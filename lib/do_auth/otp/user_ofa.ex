defmodule DoAuth.Otp.UserOfa do
  @moduledoc """
  Rest for one, ensuring that if UserReg crashes, UserSup crashes too, restarting, rereading stuff from persistent database and reregistering registered users with user registry.

  OTP Tree:

  ```
      (user_ofa is Supervisor) -- (user_reg is Registry U Agent)
              /
      (user_sup is DynamicSupervisor)
          |    |   |
       (user) ... (user is GenServer)
  ```

  """

  use Supervisor, restart: :permanent

  defp primary_children() do
    [
      DoAuth.Otp.UserReg,
      DoAuth.Otp.UserSup
    ]
  end

  @spec start_link(any) :: {:error, any} | {:ok, pid} | {:ok, pid, any}
  def start_link(initx) do
    Supervisor.start_link(__MODULE__, initx, name: __MODULE__)
  end

  @impl true
  def init(_initx) do
    Supervisor.init(primary_children(), strategy: :one_for_all)
  end
end
