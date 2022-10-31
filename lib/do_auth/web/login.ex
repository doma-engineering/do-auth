defmodule DoAuth.Web.Login do
  @moduledoc """
  A plug used to reserve the users' registration.
  """

  use Plug.Builder
  plug(:login)

  @spec login(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def login(conn, _) do
    conn
  end

end
