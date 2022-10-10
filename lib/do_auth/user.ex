defmodule DoAuth.User do
  @moduledoc """
  A corporate-friendly user auth system with E-Mail password reset capability.
  """
  import Algae

  use GenServer, restart: :transient

  alias DoAuth.Otp.UserReg, as: Reg
  alias Uptight.Text, as: T
  alias Uptight.Base.Urlsafe, as: U
  alias Uptight.Base, as: B

  alias DoAuth.Crypto
  alias DoAuth.Otp.UserSup
  alias DoAuth.Credential
  alias DoAuth.Mail
  alias DoAuth.Mailer
  alias Uptight.Result

  import Uptight.Assertions

  @dialyzer {:no_return, {:new, 0}}
  @dialyzer {:no_return, {:new, 1}}

  defdata do
    email :: T.t()
    nickname :: T.t()
    cred_id :: U.t() | nil \\ nil
  end

  @spec by_email!(T.t()) :: pid()
  def by_email!(%T{} = email) do
    [pid] =
      Registry.select(Reg, [
        {
          {:"$1", :"$2", :"$3"},
          [{:==, :"$1", email}],
          [:"$2"]
        }
      ])

    pid
  end

  @spec by_email(T.t()) :: Result.t()
  def by_email(%T{} = email) do
    Result.new(fn ->
      by_email!(email)
    end)
  end

  @spec cred_by_pid!(pid()) :: map()
  def cred_by_pid!(pid) do
    %{cred_id: id} = get_state!(pid)
    Credential.tip(id)
  end

  @spec start_link(list(T.t())) :: :ignore | {:error, any} | {:ok, pid}
  def start_link([%T{} = email, %T{} = nickname] = _x) do
    state0 =
      case Persist.load_state({__MODULE__, email}) do
        # TODO: This is nonsense
        nil -> new(email, nickname)
        state -> state
      end

    GenServer.start_link(__MODULE__, {email, state0}, name: {:via, Registry, {Reg, email}})
  end

  def start_link(_) do
    :ignore
  end

  @impl true
  @spec init({atom | pos_integer | Uptight.Text.t(), any}) :: {:ok, any}
  def init({email, state0}) do
    Persist.save_state(state0, {__MODULE__, email})
    {:ok, state0}
  end

  @spec approve_confirmation!(T.t(), keyword()) :: :ok
  def approve_confirmation!(%T{} = email, opts \\ []) do
    state0 = get_state!(email)
    confirmation_cred_id = state0.cred_id
    cred1_id = mk_approval_cred!(confirmation_cred_id, opts)
    update_state!(email, %{state0 | cred_id: cred1_id})
  end

  @spec reserve_identity(T.t(), T.t(), keyword(T.t())) :: Result.t()
  def reserve_identity(%T{} = email, %T{} = nickname, opts \\ []) do
    Result.new(fn ->
      case by_email(email) do
        %Result.Ok{ok: pid} ->
          cred = cred_by_pid!(pid)

          assert cred["credentialSubject"], "Stored credential is actually not a credential."

          assert Crypto.verify_map(cred) |> Result.is_err?(),
                 "E-Mail #{email.text} is still reserved."

          pid

        _ ->
          {ok, pid} = UserSup.start_bucket(email, nickname)

          assert match?(:ok, ok),
                 "The user with E-mail #{email.text} is already registered."

          on_reserve_identity(email, nickname, pid, opts)
          pid
      end
    end)
  end

  defp on_reserve_identity(email, nickname, pid, opts) do
    secret = make_shared_secret()
    homebase = opts[:homebase] || "localhost" |> T.new!()

    %{"id" => id} = mk_confirmation_cred!(secret, email.text, nickname.text, homebase.text, opts)

    GenServer.call(
      pid,
      {:replace_state, %__MODULE__{email: email, nickname: nickname, cred_id: B.mk_url!(id)}}
    )

    if !opts[:no_mail] do
      Mail.confirmation(secret, email, nickname, opts) |> Mailer.deliver_now!()
    end
  end

  @spec reservation_seconds() :: non_neg_integer()
  def reservation_seconds(), do: 15 * 60

  defp mk_confirmation_cred!(%U{encoded: secret}, email, nickname, homebase, opts) do
    kp = %{public: pk} = Crypto.server_keypair()

    kp
    |> Credential.transact_cred(
      %{
        "email" => email,
        "nickname" => nickname,
        "kind" => "email confirmation",
        "secret" => secret,
        "homebase" => homebase
      },
      amendingKeys: [B.safe!(pk).encoded],
      validUntil: opts[:validUntil] || Tau.now() |> DateTime.add(reservation_seconds(), :second)
    )
    |> Result.from_ok()
  end

  @spec mk_approval_cred!(U.t(), keyword()) :: U.t()
  def mk_approval_cred!(confirmation_cred_id, opts) do
    cred = Credential.tip(confirmation_cred_id)

    cget = fn x -> cred["credentialSubject"][x] end

    approval_cred =
      Crypto.server_keypair()
      |> Credential.transact_amend(
        %{
          "email" => cget.("email"),
          "nickname" => cget.("nickname"),
          "kind" => "approved",
          "reasons" => ["email" | Crypto.canonicalise_term!(opts[:reasons] || [])]
        },
        cred
      )
      |> Result.from_ok()

    approval_cred["id"] |> B.mk_url!()
  end

  defp make_shared_secret() do
    Crypto.randombytes(8)
  end

  @spec get_state!(T.t() | pid()) :: __MODULE__.t()
  def get_state!(%T{} = email) do
    pid = by_email!(email)
    GenServer.call(pid, :get_state)
  end

  def get_state!(pid) when is_pid(pid) do
    GenServer.call(pid, :get_state)
  end

  # Replace old state (state) with new state (state1)
  @spec update_state!(T.t(), __MODULE__.t()) :: :ok
  def update_state!(email, state1) do
    pid = by_email!(email)
    GenServer.cast(pid, {:update_state, state1})
  end

  # def update_state!(num, state1) when is_integer(num) do
  #   pid = by_num!(num)
  #   GenServer.call(pid, {:update_state, state1})
  # end

  # Modify state using function f.
  @spec modify_state!(T.t(), (__MODULE__.t() -> __MODULE__.t())) :: __MODULE__.t()
  def modify_state!(%T{} = email, f) do
    pid = by_email!(email)
    GenServer.call(pid, {:modify_state, f})
  end

  ######## GEN SERVER HANDLERS! #####################################################

  @impl true
  @spec handle_call(:get_state, {pid, any}, __MODULE__.t()) ::
          {:reply, __MODULE__.t(), __MODULE__.t()}
  def handle_call(:get_state, _from, state0) do
    # TODO: return latest version of credential with `tip`.
    # last_cred_id = Credential.tip(state0.cred_id)
    # state1 = %{state0 | cred_id: last_cred_id}
    {:reply, state0, state0}
  end

  # Replace old state (state) with new state (state1), and return old state.
  def handle_call({:replace_state, state1}, _from, state) do
    {:reply, state, state1}
  end

  # Modify state using function f.
  def handle_call({:modify_state, f}, _from, state) do
    state1 = f.(state)
    {:reply, state1, state1}
  end

  # Silently replace old state (state) with new state (state1).
  @impl true
  @spec handle_cast({:update_state, any()}, __MODULE__.t()) ::
          {:noreply, __MODULE__.t()}
  def handle_cast({:update_state, state1}, _state) do
    {:noreply, state1}
  end
end
