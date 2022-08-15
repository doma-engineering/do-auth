defmodule DoAuth.User do
  @moduledoc """
  A corporate-friendly user auth system with E-Mail password reset capability.
  """
  import Algae

  use GenServer, restart: :transient

  alias DoAuth.Otp.UserReg, as: Reg
  alias Uptight.Text, as: T
  alias Uptight.Base.Urlsafe, as: U

  alias DoAuth.Crypto
  alias DoAuth.Otp.UserSup
  alias DoAuth.Credential
  alias DoAuth.Mail
  alias DoAuth.Mailer
  alias Uptight.Result

  import Uptight.Assertions

  defdata do
    email :: T.t() | nil \\ nil
    nickname :: T.t() | nil \\ nil
    cred :: U.t() | nil \\ nil
  end

  @spec by_email!(T.t()) :: __MODULE__.t()
  def by_email!(email) do
    [pid] =
      Registry.select(Reg, [
        {
          {:"$1", :"$2", :"$3"},
          [{:==, :"$1", email}],
          [:"$2"]
        }
      ])

    GenServer.call(pid, :get_state)
  end

#  (2nd point) I'm not sure I've done correctly you wrote about corresponding user's process
  def by_seed(email) do
    case Result.new(fn ->
      by_email!(email)
    end) do
      %Result.Err{} = err -> err
      %Result.Ok{ok: {_, res, new_state}} -> {:reply, %Result.Ok{ok: res}, new_state}
    end
  end

  @spec start_link(list(T.t())) :: :ignore | {:error, any} | {:ok, pid}
  def start_link([%T{} = email, %T{} = nickname] = x) do
    _e = email |> T.un()
    _n = nickname |> T.un()

    GenServer.start_link(__MODULE__, %{"email" => email, "nickname" => nickname},
      name: {:via, Registry, {Reg, email}}
    )
  end

  def start_link(_) do
    :ignore
  end

  @impl true
  def init(initxkv) do
    {:ok, new(initxkv["email"], initxkv["nickname"])}
  end

  @spec park_identity(T.t(), T.t(), keyword(T.t())) :: Result.t()
  def park_identity(%T{} = email, %T{} = nickname, opts \\ []) do
    case Result.new(fn ->
           assert UserSup.start_bucket(email, nickname) |> elem(0) == :ok,
                  "The user with E-mail #{email.text} is already registered."
         end) do
      %Result.Err{} = err -> err
      ok -> on_park_identity(email, nickname, opts)
    end
  end

  defp on_park_identity(email, nickname, opts) do
    secret = make_shared_secret()
    homebase = opts[:homebase] || "localhost" |> T.new!()
    confirmation_cred = mk_confirmation_cred(secret, email.text, nickname.text, homebase.text)
    Mail.confirmation(secret, email, nickname, homebase) |> Mailer.deliver_now!()

#   (1st point) I think that this way we can save parked credentials with email in our state this way
    state1 = %__MODULE__{
      credentials: Map.put_new(cs, email.text, confirmation_cred),
      amendments: ams,
      known_payloads: ps
    }
    Persist.save_state(state1, __MODULE__)
  end

  defp mk_confirmation_cred(%U{encoded: x}, email, nickname, homebase) do
    Crypto.server_keypair()
    |> Credential.transact_cred(%{
      "email" => email,
      "nickname" => nickname,
      "kind" => "email confirmation",
      "secret" => x,
      "homebase" => homebase
    })
  end

  defp make_shared_secret() do
    Crypto.randombytes(8)
  end

  ######## GEN SERVER HANDLERS! #####################################################

  @spec handle_call(:get_state, {pid, any}, __MODULE__.t()) ::
          {:reply, __MODULE__.t(), __MODULE__.t()}
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
