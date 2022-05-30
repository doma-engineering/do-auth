defmodule DoAuth.Credential do
  @moduledoc """
  Generic verifiable credentials server and library functions to make and operate those.

  Please write as little as possible here, instead make your own GenServers that will write down and navigate domain-specific credentials.
  """
  use GenServer
  alias Uptight.Base, as: B
  alias Uptight.Text, as: T
  alias Uptight.Result

  alias DoAuth.Crypto

  defstruct credentials: %{}, amendments: %{}, known_payloads: %{}
  @type state :: %__MODULE__{}

  #### PURE LIBRARY FUNCTIONS, SORTED BY IMPORTANCE ##############################################

  @doc """
  Stateful version of this function: `transact_cred`.

  Takes a binary public key embedded into a keypair, payload map aka rich "credentialSubject" and some options, meaningful ones are:

      + :issuanceDate :: Date.t() as string
      + :effectiveDate :: Date.t() as string
      + :validFrom :: Date.t() as string
      + :validUntil :: Date.t() as string
      + :id (trumps synonymous :location) :: base64 encoded thing that can be used to address the credential stored on a server
      + :amendingKeys :: [base64 (public keys)] list of keys that can issue verifiable amendments to the server

  """
  @spec mk_credential!(
          %{:public => Uptight.Binary.t(), optional(any) => any},
          map,
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
    oput! = &DynHacks.put_new_value(&1, &2, oget.(&2))

    cred_so_far =
      %{
        "@context" => [],
        "type" => "fact",
        "issuer" => issuer,
        "issuanceDate" => tau0,
        "credentialSubject" => payload_map
      }
      |> tau_oput!.("issuanceDate")
      |> tau_oput.("effectiveDate")
      |> tau_oput.("validFrom")
      |> tau_oput.("validUntil")
      |> oput!.("amendingKeys")
      |> oput!.("type")

    cred_so_far =
      if :amends in opts do
        cred_so_far
        |> Map.put("type", "amendment")
        |> Map.put("amends", Keyword.get(opts, :amends))
      else
        cred_so_far
      end

    proof = mk_proof(kp, cred_so_far, opts)

    cred_so_far |> Map.put("proof", proof) |> Map.put("id", proof["signature"])
  end

  @doc """
  Stateful version of this function: `transact_present`.

  Just present a credential map in form of a verifiable presentation without checking that it's not amended.
  """
  @spec present_credential_map(
          Crypto.keypair(),
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
          "type" => "presentation",
          "verifiableCredential" => credential_map,
          "issuer" => issuer_str
        }
        |> p.("holder", o.(:holder))
        |> p.("credentialSubject", o.(:credentialSubject))
        |> p.("amendingKeys", o.(:amendingKeys))
        |> tau_oput!.("issuanceDate")

      res = Crypto.sign_map!(kp, presentation_claim, opts)
      res |> Map.put("id", res["proof"]["signature"])
    end)
  end

  @doc """
  Stateful version of this function: `transact_amend`.

  Just amend a credential map without checking that it's not amended.
  """
  @spec amend_credential_map(
          Crypto.keypair(),
          map(),
          any(),
          list()
        ) :: Result.t()
  def amend_credential_map(
        %{public: pk} = kp,
        %{} = payload_map,
        %{} = credential_map,
        opts \\ []
      ) do
    Result.new(fn ->
      issuer = pk |> B.safe!()

      {["issuer", ^issuer, "can amend credential"], true} =
        {["issuer", issuer, "can amend credential"], issuer in credential_map["amendingKeys"]}

      opts =
        if :amendingKeys in opts do
          opts
        else
          opts |> Keyword.put(:amendingKeys, credential_map["amendingKeys"])
        end

      mk_credential!(
        kp,
        payload_map,
        Keyword.merge([type: "amendment", amends: credential_map["id"]], opts)
      )
    end)
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

  @spec present_credential_map!(
          Crypto.keypair_opt(),
          map(),
          list()
        ) :: map
  def present_credential_map!(kp, credential_map, opts \\ []) do
    present_credential_map(kp, credential_map, opts) |> Result.from_ok()
  end

  @spec hash_map!(Crypto.canonicalisable_value()) :: String.t()
  def hash_map!(cred) do
    Crypto.canonicalise_term!(cred) |> Jason.encode!() |> Crypto.bland_hash()
  end

  @spec hash_map(Crypto.canonicalisable_value()) :: Result.t()
  def hash_map(cred) do
    Result.new(fn ->
      hash_map!(cred)
    end)
  end

  #### SERVER API, IT'S VERY BORING BUT VERY IMPORTANT ###########################################

  @spec transact_cred(Crypto.keypair_opt(), map(), keyword()) ::
          {:reply, Result.t(), list()}
  def transact_cred(kp, payload_map, opts \\ []) do
    GenServer.call(__MODULE__, {:mk_credential, kp, payload_map, opts})
  end

  @spec transact_present(Crypto.keypair(), map(), keyword()) ::
          {:reply, Result.t(), list()}
  def transact_present(kp, credential_map, opts \\ []) do
    GenServer.call(__MODULE__, {:present_credential, kp, credential_map, opts})
  end

  @spec transact_amend(Crypto.keypair(), map(), map(), keyword()) ::
          {:reply, Result.t(), list()}
  def transact_amend(kp, payload_map, credential_map, opts \\ []) do
    GenServer.call(__MODULE__, {:amend_credential, kp, payload_map, credential_map, opts})
  end

  @spec all(B.Urlsafe.t()) :: nil | list(map())
  def all(x), do: get(x, mode: :all)
  @spec all64(String.t()) :: nil | list(map())
  def all64(x), do: get64(x, mode: :all)

  @spec tip(B.Urlsafe.t()) :: nil | map()
  def tip(x), do: get(x, mode: :just_the_tip)
  @spec tip64(String.t()) :: nil | map()
  def tip64(x), do: get64(x, mode: :just_the_tip)

  @spec get(B.Urlsafe.t(), list()) :: nil | map() | list(map())
  def get(%B.Urlsafe{encoded: xenc}, opts \\ [mode: :get]), do: get64(xenc, opts)

  @spec get64(String.t(), list()) :: nil | map() | list(map())
  def get64(x, opts \\ [mode: :get]), do: GenServer.call(__MODULE__, {:get, x, opts[:mode]})

  #### SEVER BACKEND ############################################################################

  @spec handle_call(tuple, {pid, any()}, state()) :: {:reply, any(), state()}
  ## mk_credential <~ transact_cred or transact_present #########################################
  def handle_call(
        {mk_or_present_cred, kp, payload_map, opts},
        _from,
        %__MODULE__{known_payloads: ps, credentials: cs, amendments: ams} = state
      )
      when mk_or_present_cred == :mk_credential or mk_or_present_cred == :present_credential do
    fetch_cred_maybe = fn ->
      payload_hash = hash_map!(payload_map)

      existing = Map.get(ps, payload_hash)

      res = (is_nil(existing) && new_cred(mk_or_present_cred, kp, payload_map, opts)) || existing

      state1 = %__MODULE__{
        credentials: Map.put_new(cs, res["id"], res),
        amendments: ams,
        known_payloads: Map.put_new(ps, payload_hash, res["id"])
      }

      {res, state1}
    end

    case Result.new(fn ->
           (is_nil(opts[:persist]) &&
              {new_cred(mk_or_present_cred, kp, payload_map, opts), state}) ||
             fetch_cred_maybe.()
         end) do
      %Result.Ok{ok: {cred, state1}} -> {:reply, %Result.Ok{ok: cred}, state1}
      %Result.Err{} = e -> {:reply, e, state}
    end
  end

  ## :amend_credential <~ transact_amend(...) ###################################################
  def handle_call(
        {:amend_credential, kp, payload_map, credential_map, opts},
        _from,
        %__MODULE__{known_payloads: ps, credentials: cs, amendments: ams} = state
      ) do
    prev_id = credential_map["id"]

    register_amended = fn new_c, old_c ->
      %__MODULE__{
        known_payloads: Map.delete(ps, hash_map!(old_c |> get_payload())),
        amendments: Map.put(ams, prev_id, new_c["id"]),
        credentials: Map.put(cs, new_c["id"], new_c)
      }
    end

    case get_credential_chain(prev_id, cs, ams) do
      [tip | _] ->
        res = amend_credential_map(kp, payload_map, tip, opts)

        (Result.is_ok?(res) && {:reply, res, register_amended.(res[:ok], tip)}) ||
          {:reply, res, state}

      _ ->
        {:reply,
         Result.new(fn ->
           %{"credential that has to be amended found" => false} = %{
             "credential that has to be amended found" => prev_id
           }
         end)}
    end
  end

  ## :get <~ get(...) ###########################################################################
  def handle_call({:get, id, mode}, _from, %__MODULE__{credentials: cs} = state)
      when mode == :get or mode == nil do
    {:reply, Map.get(cs, id), state}
  end

  def handle_call({:get, id, mode}, _from, %__MODULE__{credentials: cs, amendments: ams})
      when mode == :just_the_tip or mode == :all do
    case get_credential_chain(id, cs, ams) do
      [res | _] = xs -> (mode == :all && xs) || res
      _otherwise -> nil
    end
  end

  @spec handle_cast(tuple(), map()) :: {:noreply, map()}
  def handle_cast({:persist, cred}, state) do
    {:noreply,
     Map.put_new(
       state,
       %{
         "verifiableCredential" => cred["verifiableCredential"],
         "credentialSubject" => cred["credentialSubject"]
       },
       cred
     )}
  end

  #### PRIVATE FUNCTIONS ########################################################################

  defp new_cred(mk_or_present_cred, kp, payload_map, opts) do
    case mk_or_present_cred do
      :mk_credential ->
        mk_credential!(kp, payload_map, opts)

      :present_credential ->
        present_credential_map!(kp, payload_map, opts)
    end
  end

  defp get_credential_chain(id, cs, ams, acc \\ nil) do
    if is_nil(acc) do
      res = Map.get(cs, id)

      if is_nil(res) do
        nil
      else
        get_credential_chain(id, cs, ams, [res])
      end
    end

    rid = Map.get(ams, id)

    if is_nil(rid) do
      acc
    else
      res = Map.get(cs, rid)
      get_credential_chain(rid, cs, ams, [res | acc])
    end
  end

  defp get_payload(c) do
    c["credentialSubject"]
  end

  defp time_getter(x, oget) do
    tau_maybe = oget.(x)

    case tau_maybe do
      x = %{} -> DateTime.to_iso8601(x)
      otherwise -> otherwise
    end
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

  defp mk_proof(kp, cred_so_far, opts) do
    (Keyword.has_key?(opts, :signature) &&
       Crypto.sig64_to_proof_map(kp[:public], opts[:signature], opts[:timestamp])) ||
      Crypto.sign_map!(kp, cred_so_far, opts) |> Map.get("proof")
  end

  #### BORING GEN_SERVER ENDPOINTS ###########################################################

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  @spec init(any) :: {:ok, map()}
  def init(_args) do
    {:ok, %__MODULE__{}}
  end
end
