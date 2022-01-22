defmodule DoAuth.Credential do
  @moduledoc """
  Generic verifiable credentials server.
  """
  use GenServer
  alias Uptight.Base, as: B
  alias Uptight.Text, as: T
  alias Uptight.Binary
  alias Uptight.Result

  alias DoAuth.Crypto

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  @spec init(any) :: {:ok, map()}
  def init(_args) do
    {:ok, %{}}
  end

  @spec content(map) :: map
  def content(cred) do
    cred["credentialSubject"]
  end

  @spec sig(map) :: B.Urlsafe.t()
  def sig(cred) do
    cred["proof"]["signature"] |> B.mk_url!()
  end

  @spec pk(map) :: B.Urlsafe.t()
  def pk(cred) do
    cred["proof"]["verificationMethod"] |> B.mk_url!()
  end

  @spec transact_with_keypair_from_payload_map!(Crypto.keypair_opt(), map(), keyword()) ::
          {:reply, map(), list()}
  def transact_with_keypair_from_payload_map!(kp, payload_map, opts \\ []) do
    GenServer.call(__MODULE__, {:mk_credential, kp, payload_map, opts})
  end

  @spec handle_call(tuple, {pid, any()}, list) :: {:reply, any(), list()}
  def handle_call({:mk_credential, kp, payload_map, opts}, _from, state) do
    mk_cred = fn ->
      mk_credential!(kp, payload_map, opts)
    end

    cred =
      if opts[:persist] |> is_nil() do
        mk_cred.()
      else
        res = Map.get_lazy(state, key_from_subject(payload_map), mk_cred)
        GenServer.cast(__MODULE__, {:persist, res})
        res
      end

    {:reply, cred, state}
  end

  defp key_from_subject(payload_map) do
    %{"verifiableCredential" => nil, "credentialSubject" => payload_map}
  end

  def handle_cast({:persist, cred}, state) do
    {:noreply,
     Map.put_new(
       state,
       # TODO: While we appreciate deduplication effort, we should reduce storage overhead at some point here.
       # Furthermore, akin to invite storage system, we should track creds based on the signatures here
       %{
         "verifiableCredential" => cred["verifiableCredential"],
         "credentialSubject" => cred["credentialSubject"]
       },
       cred
     )}
  end

  @spec present_credential_map!(
          Crypto.keypair_opt(),
          map(),
          list()
        ) :: map
  def present_credential_map!(kp, credential_map, opts \\ []) do
    present_credential_map(kp, credential_map, opts) |> Result.from_ok()
  end

  @spec present_credential_map(
          Crypto.keypair_opt(),
          map(),
          list()
        ) :: Result.t()
  def present_credential_map(%{public: pk} = kp, %{} = credential_map, opts \\ []) do
    Result.new(fn ->
      p = &DynHacks.put_new_value(&1, &2, &3)
      o = &Keyword.get(opts, &1)
      oget = &Keyword.get(opts, &1 |> String.to_atom())

      tau_oget = fn x ->
        time_getter(x, oget)
      end

      tau_oput! = &DynHacks.put_value(&1, &2, tau_oget.(&2))

      issuer_str = pk |> B.safe!() |> Map.get(:encoded)

      presentation_claim =
        %{
          "verifiableCredential" => credential_map,
          "issuer" => issuer_str
        }
        |> p.("id", o.(:location))
        |> p.("holder", o.(:holder))
        |> p.("credentialSubject", o.(:credential_subject))
        |> tau_oput!.("issuanceDate")

      Crypto.sign_map!(kp, presentation_claim, opts)
    end)
  end

  defp time_getter(x, oget) do
    tau_maybe = oget.(x)

    case tau_maybe do
      x = %{} -> DateTime.to_iso8601(x)
      otherwise -> otherwise
    end
  end

  @spec mk_credential!(
          %{:public => Uptight.Binary.t(), optional(any) => any},
          any,
          keyword
        ) :: map
  def mk_credential!(
        %{public: pk} = kp,
        payload_map,
        opts \\ []
      ) do
    tau0 = with_opts_get_timestamp_str(opts)
    did = pk |> B.safe!()
    issuer = did.encoded
    oget = &Keyword.get(opts, &1 |> String.to_atom())

    tau_oget = fn x ->
      tau_maybe = oget.(x)

      case tau_maybe do
        x = %{} -> DateTime.to_iso8601(x)
        otherwise -> otherwise
      end
    end

    tau_oput = &DynHacks.put_new_value(&1, &2, tau_oget.(&2))
    tau_oput! = &DynHacks.put_value(&1, &2, tau_oget.(&2))
    oput2 = &DynHacks.put_new_value(&1, &2, oget.(&3))

    cred_so_far =
      %{
        "@context" => [],
        "type" => [],
        "issuer" => issuer,
        "issuanceDate" => tau0,
        "credentialSubject" => payload_map
      }
      |> tau_oput!.("issuanceDate")
      |> tau_oput.("effectiveDate")
      |> tau_oput.("validFrom")
      |> tau_oput.("validUntil")
      |> oput2.("id", "location")

    proof =
      mk_signature_with_opts(kp, cred_so_far, opts) |> proof_from_raw_sig(issuer, tau0, opts)

    # I think that ID is a horrible feature and we should probably just get rid of it.
    id =
      case Map.get(cred_so_far, "id") do
        nil ->
          proof["signature"]

        x ->
          x
      end

    cred_so_far |> Map.put("proof", proof) |> Map.put("id", id)
  end

  defp with_opts_get_timestamp_str(opts) do
    with_opts_get_timestamp(opts) |> DateTime.to_iso8601(:extended, 0)
  end

  defp with_opts_get_timestamp(opts) do
    if Keyword.has_key?(opts, :timestamp) do
      case opts[:timestamp] do
        <<x::binary>> -> Tau.from_raw_utc_iso8601!(x)
        %T{} = x -> Tau.from_utc_iso8601!(x)
        %DateTime{} = x -> x
      end
    else
      Tau.now()
    end
  end

  defp mk_signature_with_opts(kp, cred_so_far, opts) do
    if Keyword.has_key?(opts, :signature) do
      opts[:signature]
    else
      signed =
        cred_so_far
        |> Crypto.canonicalise_term!()
        |> Crypto.canonical_sign!(kp)

      signed
      |> Map.get(:signature)
      |> Binary.un()
    end
  end

  defp proof_from_raw_sig(sig_raw, issuer, tau0, _opts) do
    %{
      "created" => tau0,
      "verificationMethod" => issuer,
      "type" => "Libsodium2021",
      "proofPurpose" => "assertionMethod",
      "signature" => sig_raw |> B.raw_to_urlsafe!() |> Map.get(:encoded)
    }
  end
end
