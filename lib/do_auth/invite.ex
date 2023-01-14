defmodule DoAuth.Invite do
  @moduledoc """
  Invite management server.
  """
  use GenServer

  alias DoAuth.Crypto
  alias DoAuth.Credential

  alias Uptight.Base, as: B
  alias Uptight.Result

  require Logger

  import DynHacks

  import Uptight.Assertions

  # TODO: State???

  @default_invites 2
  @max_persists 10

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(init_args) do
    r_m(
      GenServer.start_link(__MODULE__, [init_args], name: __MODULE__),
      fn _ -> GenServer.cast(__MODULE__, :persist) end
    )
  end

  @spec safe_server_keypair() :: B.Urlsafe.t()
  def safe_server_keypair() do
    Crypto.server_keypair()[:public] |> B.safe!()
  end

  @spec init(any) :: {:ok, map()}
  def init(_args) do
    state0 =
      case Persist.load_state(__MODULE__) do
        nil ->
          spk = safe_server_keypair()
          root_invite = mk_invites(spk, 100_000)
          root_invite_id = sig(root_invite)

          # TODO: We should move state to struct when we finish the logic!

          %{
            "fulfillments" => %{},
            "invites" => %{root_invite_id => root_invite},
            "views" => %{"public_key" => %{}, "root" => root_invite_id},
            "registered_keys" => %{spk.encoded => root_invite_id}
          }

        some_state ->
          some_state
      end

    # Logger.info(
    #   "Invite server is starting with the following state: #{inspect(state0, pretty: true)}"
    # )

    {:ok, state0}
  end

  @spec unpaid_users_allowed_until :: DateTime.t()
  def unpaid_users_allowed_until() do
    ~N[2024-02-23 20:22:02] |> DateTime.from_naive!("Etc/UTC")
  end

  @spec remind_to_pay_from :: DateTime.t()
  def remind_to_pay_from() do
    ~N[2023-01-23 20:22:01] |> DateTime.from_naive!("Etc/UTC")
  end

  @spec mk_invites(B.Urlsafe.t(), pos_integer(), keyword()) :: map()
  def mk_invites(pk, capacity \\ @default_invites, opts \\ []) do
    Credential.mk_credential!(
      Crypto.binary_server_keypair(),
      %{
        "kind" => "invite",
        "holder" => pk.encoded,
        "capacity" => capacity
      }
      |> Map.merge(remind_maybe(opts)),
      timed_maybe(opts)
    )
  end

  defp timed_maybe(opts) do
    if opts[:premium] do
      [validUntil: unpaid_users_allowed_until()]
    else
      []
    end
  end

  defp remind_maybe(opts) do
    if opts[:premium] do
      %{
        "paymentEnrollmentReminder" => remind_to_pay_from() |> DateTime.to_iso8601()
      }
    else
      %{}
    end
  end

  @spec lookup(B.Urlsafe.t()) :: map | nil
  def lookup(urlsafe_pk) do
    GenServer.call(__MODULE__, {:lookup, urlsafe_pk.encoded})
  end

  @spec grant_root_invite() :: Result.t()
  def grant_root_invite() do
    Result.new(fn ->
      invite = get_root_invite()
      assert is_invite_vacant(invite), "Invite must not be already fulfilled."
      is_valid = Crypto.verify_map(invite)
      assert Result.is_ok?(is_valid), "Invite must be a valid credential."

      r_m(
        Credential.present_credential_map!(Crypto.binary_server_keypair(), invite,
          credentialSubject: %{"generatedAt" => Tau.now() |> Crypto.canonicalise_term!()}
        ),
        &register_fulfillment(invite, &1)
      )
    end)
  end

  @doc """
  Call this ONLY IF you used a side-channel to validate that the person making request is a human.
  """
  @spec fulfill_simple(map) :: Result.t()
  def fulfill_simple(cred) do
    Result.new(fn ->
      pk = cred["credentialSubject"]["me"] |> B.mk_url!()
      pk_authored = cred["proof"]["verificationMethod"] |> B.mk_url!()

      %{"keys match" => true} = %{"keys match" => pk == pk_authored}

      %{"public key is not registered" => true} = %{
        "public key is not registered" => is_public_key_unregistered(pk)
      }

      %{"credential is valid" => true} = %{
        "credential is valid" => Crypto.verify_map(cred) |> Result.is_ok?()
      }

      root_invite = get_root_invite()
      true = Crypto.verify_map(root_invite) |> Result.is_ok?()

      r_m(
        Credential.mk_credential!(Crypto.binary_server_keypair(), %{
          "invite" => sig(root_invite),
          "holder" => pk.encoded,
          # TODO: Make use of names
          "name" => cred["credentialSubject"]["name"],
          "kind" => "fulfill"
        }),
        fn x ->
          register_fulfillment(sig(root_invite), x)
          register_public_key(x)
        end
      )
    end)
  end

  @spec register_fulfillment(map(), map()) :: :ok
  def register_fulfillment(invite_id, cred) do
    GenServer.call(__MODULE__, {:register_fulfillment, invite_id, cred})
  end

  @spec fulfill(B.Urlsafe.t(), map) :: Result.t()
  def fulfill(pk, invite_presentation_map) do
    GenServer.call(__MODULE__, {:fulfill, pk, invite_presentation_map})
  end

  defp register_public_key(fulfillment_cred) do
    pk = fulfillment_cred["credentialSubject"]["holder"]
    fulfillment_id = sig(fulfillment_cred)
    GenServer.call(__MODULE__, {:register_public_key, pk, fulfillment_id})
    GenServer.cast(__MODULE__, :persist)
  end

  defp register_public_key1(fulfillment_cred, state) do
    pk = fulfillment_cred["credentialSubject"]["holder"]
    fulfillment_id = sig(fulfillment_cred)
    register_public_key_state(pk, fulfillment_id, state)
  end

  @spec is_public_key_unregistered(B.Urlsafe.t()) :: boolean()
  def is_public_key_unregistered(pk) do
    GenServer.call(__MODULE__, {:lookup, pk.encoded}) |> is_nil()
  end

  @spec get_by_sig(B.Urlsafe.t()) :: map | nil
  def get_by_sig(sig) do
    GenServer.call(__MODULE__, {:get, sig.encoded})
  end

  @spec get(map) :: map | nil
  def get(invite) do
    GenServer.call(__MODULE__, {:get, sig(invite)})
  end

  # We use signatures as credential IDs
  defp sig(cred) do
    cred["proof"]["signature"]
  end

  defp is_invite_vacant(invite) do
    invite["credentialSubject"]["capacity"] > get_fulfillments(invite) |> Enum.count()
  end

  defp holder(pres) do
    pres["verifiableCredential"]["credentialSubject"]["holder"]
  end

  defp issuer(pres) do
    pres["issuer"]
  end

  defp is_presenter_the_holder(invite_presentation_map) do
    holder(invite_presentation_map) == issuer(invite_presentation_map["verifiableCredential"])
  end

  defp get_fulfillments(%{} = invite_presentation_map) do
    GenServer.call(__MODULE__, {:get_fulfillments, sig(invite_presentation_map)})
  end

  defp is_contemporary(cred) do
    tau0 = Tau.now()

    g = &Map.get(cred, &1, &2)

    valid_from = g.("validFrom", g.("effectiveDate", g.("issuanceDate", nil)))

    valid_until = g.("validUntil", g.("expirationDate", nil))

    true =
      if valid_from == nil do
        throw(ArgumentError.message(%{message: "issuanceDate is missing"}))
      else
        {:ok, valid_from, 0} = valid_from |> DateTime.from_iso8601()
        Enum.member?([:gt, :eq], DateTime.compare(tau0, valid_from))
      end

    true =
      if valid_until == nil do
        true
      else
        {:ok, valid_until, 0} = valid_until |> DateTime.from_iso8601()
        Enum.member?([:lt, :eq], DateTime.compare(tau0, valid_until))
      end

    true
  end

  defp get_root_invite() do
    GenServer.call(__MODULE__, :get_root_invite)
  end

  def handle_call({:fulfill, pk, invite_presentation_map}, _from, state) do
    case Result.new(fn ->
           assert lookup1(pk.encoded, state) |> is_nil(),
                  "Public key #{pk.encoded} is not registered."

           pres_id = sig(invite_presentation_map)
           assert %{} = by_sig(pres_id, state), "Invite #{pres_id} is registered."

           assert is_presenter_the_holder(invite_presentation_map),
                  "Presenter of the invite is also the holder."

           assert [] == fulf_by_sig(pres_id, state), "Presentation of the invite isn't used up."

           assert Crypto.verify_map(invite_presentation_map) |> Result.is_ok?(),
                  "Presentation is valid."

           invite_credential_map = invite_presentation_map["verifiableCredential"]
           cred_id = sig(invite_credential_map)

           assert invite_credential_map["credentialSubject"]["capacity"] >
                    fulf_by_sig(cred_id, state) |> Enum.count(),
                  "The invite itself has vacant spots."

           assert is_contemporary(invite_credential_map), "The invite is currently valid."

           assert Crypto.verify_map(invite_credential_map) |> Result.is_ok?(),
                  "The invite is cryptographically sound."

           res =
             Credential.mk_credential!(Crypto.binary_server_keypair(), %{
               "invite" => cred_id,
               "presentation" => pres_id,
               "holder" => pk.encoded,
               "kind" => "fulfill"
             })

           # So we get fulfillment, which fulfills both invite and its presentation.
           # Fulfilling presentation is needed to prevent invite resharing.
           #
           # Let's capture it.

           #  state1 = register_fulfillment_state(invite_credential_map, res, state)
           #  state2 = register_fulfillment_state(invite_presentation_map, res, state1)
           state1 = register_fulfillment_state(cred_id, res, state)
           state2 = register_fulfillment_state(pres_id, res, state1)
           state3 = register_public_key1(res, state2)

           {:reply, res, state3}
         end) do
      %Result.Ok{ok: {_, res, new_state}} -> {:reply, %Result.Ok{ok: res}, new_state}
      %Result.Err{} = err -> {:reply, err, state}
    end
  end

  def handle_call({:get_fulfillments, id}, _from, %{"fulfillments" => fulfillments} = state) do
    {:reply, Map.get(fulfillments, id, []), state}
  end

  def handle_call(
        {:lookup, pk64},
        _from,
        state
      ) do
    {:reply, lookup1(pk64, state), state}
  end

  def handle_call({:mailbox, pk64}, {pid, _tag}, state) do
    if is_nil(Process.get({:mailbox, pk64})) do
      a = Process.put({:mailbox, pk64}, pid)

      if !is_nil(a) do
        Process.put({:mailbox, pk64}, a)
      end
    end

    {:reply, :ok, state}
  end

  def handle_call({:get, sig}, _from, %{"invites" => invites} = state) do
    {:reply, Map.get(invites, sig), state}
  end

  def handle_call({:register_fulfillment, parent_sig, child}, _from, state) do
    {:reply, :ok, register_fulfillment_state(parent_sig, child, state)}
  end

  def handle_call({:register_public_key, pk, invite_sig}, _from, state) do
    {:reply, :ok, register_public_key_state(pk, invite_sig, state)}
  end

  def handle_call(
        :get_root_invite,
        _from,
        %{"views" => %{"root" => root}, "invites" => invites} = state
      ) do
    # Proverb: there are no exclamation marks in gen_server handlers
    {:reply, Map.get(invites, root), state}
  end

  def handle_call({:run_lambda, f}, _from, _state) do
    y = f.()
    state1 = :sys.get_state(__MODULE__)
    {:reply, y, state1}
  end

  def handle_cast(:persist, state) do
    if Process.put(:persists, Process.get(:persists, 0) + 1) < @max_persists do
      Task.start(fn ->
        Persist.save_state(state, __MODULE__)
        GenServer.cast(__MODULE__, :persist_done)
      end)
    end

    {:noreply, state}
  end

  def handle_cast(:persist_done, state) do
    Process.put(:persists, Process.get(:persists, 0) - 1)
    {:noreply, state}
  end

  defp register_public_key_state(pk, invite_sig, state) do
    views = Map.get(state, "views")
    pks = Map.get(views, "public_key")

    if !is_nil(Map.get(pks, pk)) do
      Logger.warn("Public key was already registered #{pk}.")
    end

    %{state | "views" => %{views | "public_key" => Map.put_new(pks, pk, invite_sig)}}
  end

  defp register_fulfillment_state(
         parent_sig,
         child,
         %{"fulfillments" => fulfillments, "invites" => invites} = state
       ) do
    fs = Map.get(fulfillments, parent_sig, [])

    %{
      state
      | "fulfillments" => fulfillments |> Map.put(parent_sig, [sig(child) | fs]),
        "invites" => invites |> Map.put(sig(child), child)
    }
  end

  defp lookup1(
         pk64,
         %{"invites" => invites, "views" => %{"public_key" => pkindex}}
       ) do
    Map.get(invites, Map.get(pkindex, pk64))
  end

  defp by_sig(sig, %{"invites" => invites}) do
    Map.get(invites, sig)
  end

  defp fulf_by_sig(sig, %{"fulfillments" => fulfillments}) do
    Map.get(fulfillments, sig, [])
  end
end
