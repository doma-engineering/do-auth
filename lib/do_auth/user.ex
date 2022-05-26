defmodule DoAuth.User do
  @moduledoc """
  A corporate-friendly user auth system with E-Mail password reset capability.
  """
  import Algae

  use GenServer, restart: :transient

  alias Uptight.Text, as: T
  alias Uptight.Base.Urlsafe, as: U

  defdata do
    email :: T.t() | nil \\ nil
    nickname :: T.t() | nil \\ nil
    cred :: U.t() | nil \\ nil
  end

  def start_link(x = [%T{} = email, %T{} = nickname]) do
    IO.inspect("YOBA YOBA")
    IO.inspect("YOBA YOBA")
    IO.inspect({email, nickname})
    IO.inspect("YOBA YOBA")
    IO.inspect("YOBA YOBA")
    _e = email |> T.un()
    _n = nickname |> T.un()

    GenServer.start_link(__MODULE__, %{"email" => email, "nickname" => nickname},
      name: {:via, Registry, {DoAuth.Otp.UserReg, x}}
    )
  end

  @impl true
  def init(initxkv) do
    {:ok, new(initxkv["email"], initxkv["nickname"])}
  end

  def start_link(_) do
    :ignore
  end
end
