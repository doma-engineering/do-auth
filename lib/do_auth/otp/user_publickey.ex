defmodule DoAuth.Otp.UserPublickey do
  @moduledoc """
  An agent maintaining a registry used by UserSup -> User OTP edge.
  TODO: Probably we should rewrite this to gproc, but let's keep it like this for the time being.
  """
  use Agent

  @spec start_link(any) :: {:error, any} | {:ok, pid} | {:ok, pid, any}
  def start_link(_initx) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end
end
