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

  @default_invites 2

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(init_args) do
    r_m(
      GenServer.start_link(__MODULE__, [init_args], name: __MODULE__),
      fn _ -> GenServer.cast(__MODULE__, :persist) end
    )
  end

  @spec init(any) :: {:ok, map()}
  def init(_args) do
    state0 =
      case Persist.load_state(__MODULE__) do
        nil ->
          spk = Crypto.urlsafe_server_keypair()[:public]
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

    Logger.info(
      "Invite server is starting with the following state: #{inspect(state0, pretty: true)}"
    )

    {:ok, state0}
  end

  @spec unpaid_users_allowed_until :: DateTime.t()
  def unpaid_users_allowed_until() do
    ~N[2023-02-23 20:22:02] |> DateTime.from_naive!("Etc/UTC")
  end

  @spec remind_to_pay_from :: DateTime.t()
  def remind_to_pay_from() do
    ~N[2023-01-23 20:22:01] |> DateTime.from_naive!("Etc/UTC")
  end

  @spec mk_invites(B.Urlsafe.t(), pos_integer()) :: map()
  def mk_invites(pk, capacity \\ @default_invites) do
    Credential.mk_credential!(
      Crypto.binary_server_keypair(),
      %{
        "kind" => "invite",
        "holder" => pk.encoded,
        "capacity" => capacity,
        "paymentEnrollmentReminder" => remind_to_pay_from() |> DateTime.to_iso8601()
      },
      validUntil: unpaid_users_allowed_until()
    )
  end

  @spec lookup(B.Urlsafe.t()) :: map | nil
  def lookup(urlsafe_pk) do
    GenServer.call(__MODULE__, {:lookup, urlsafe_pk.encoded})
  end

  @spec grant_root_invite() :: Result.t()
  def grant_root_invite() do
    Result.new(fn ->
      invite = get_root_invite()
      true = is_invite_vacant(invite)
      true = Crypto.verify_map(invite) |> Result.is_ok?()

      r_m(
        Credential.present_credential_map!(Crypto.binary_server_keypair(), invite,
          credential_subject: %{"generatedAt" => Tau.now() |> Crypto.canonicalise_term!()}
        ),
        &register_fulfillment_async(invite, &1)
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
          register_fulfillment_async(root_invite, x)
          register_public_key(x)
        end
      )
    end)
  end

  @spec fulfill(B.Urlsafe.t(), map) :: Result.t()
  def fulfill(pk, invite_presentation_map) do
    Result.new(fn ->
      true = is_invite_registered(invite_presentation_map)
      true = is_presenter_the_holder(invite_presentation_map)
      true = is_public_key_unregistered(pk)
      true = is_presentation_vacant(invite_presentation_map)
      true = Crypto.verify_map(invite_presentation_map) |> Result.is_ok?()
      credential_map = invite_presentation_map["verifiableCredential"]
      true = is_invite_vacant(credential_map)
      # TODO: test that non-conemporary invites get rejected
      true = is_contemporary(credential_map)
      true = Crypto.verify_map(credential_map) |> Result.is_ok?()

      r_m(
        Credential.mk_credential!(Crypto.binary_server_keypair(), %{
          "invite" => sig(credential_map),
          "presentation" => sig(invite_presentation_map),
          "holder" => pk.encoded,
          "kind" => "fulfill"
        }),

        # So we get fulfillment, which fulfills both invite and its presentation.
        # Fulfilling presentation is needed to prevent invite resharing.
        #
        # Let's capture it.
        fn x ->
          register_fulfillment_async(credential_map, x)
          register_fulfillment_async(invite_presentation_map, x)
          register_public_key(x)
        end
      )

      # We've used async because most of the stuff is synchronous and isn't
      # spammable, so this async just takes out a little bit of latency from the
      # system and, worst case, would result in maybe an odd racy invite being
      # fulfilled that wouldn't otherwise be fulfilled. Of course, if there's an
      # error in stats update, we'll crash the server, but not request
      # handling... It's an edge case to consider, but it's a disasterous
      # situation for the whole invite subsystem.
    end)
  end

  defp register_public_key(fulfillment_cred) do
    pk = fulfillment_cred["credentialSubject"]["holder"]
    fulfillment_id = sig(fulfillment_cred)
    GenServer.call(__MODULE__, {:register_public_key, pk, fulfillment_id})
    GenServer.cast(__MODULE__, :persist)
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

  defp register_fulfillment_async(parent, child) do
    GenServer.cast(__MODULE__, {:register_fulfillment, sig(parent), child})
  end

  # We use signatures as credential IDs
  defp sig(cred) do
    cred["proof"]["signature"]
  end

  defp is_invite_registered(invite) do
    get(invite) != nil
  end

  defp is_invite_vacant(invite) do
    invite["credentialSubject"]["capacity"] > get_fulfillments(invite) |> Enum.count()
  end

  defp is_presenter_the_holder(invite_presentation_map) do
    invite_presentation_map["verifiableCredential"]["credentialSubject"]["holder"] ==
      invite_presentation_map["issuer"]
  end

  defp is_presentation_vacant(%{} = invite_presentation_map) do
    0 == get_fulfillments(invite_presentation_map) |> Enum.count()
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

  def handle_call({:get_fulfillments, id}, _from, %{"fulfillments" => fulfillments} = state) do
    {:reply, Map.get(fulfillments, id, []), state}
  end

  def handle_call(
        {:lookup, pk64},
        _from,
        %{"invites" => invites, "views" => %{"public_key" => pkindex}} = state
      ) do
    {:reply, Map.get(invites, Map.get(pkindex, pk64)), state}
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
    {:reply, Map.get(invites, root), state}
  end

  def handle_cast({:register_fulfillment, parent_sig, child}, state) do
    {:noreply, register_fulfillment_state(parent_sig, child, state)}
  end

  def handle_cast(:persist, state) do
    Task.start(fn -> Persist.save_state(state, __MODULE__) end)
    {:noreply, state}
  end

  defp register_public_key_state(pk, invite_sig, state) do
    views = Map.get(state, "views")
    pks = Map.get(views, "public_key")
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
end
