defmodule DoAuth.Web.Confirmed do
  @moduledoc """
  A plug used to see that user is logged into server registration.
  """

  use Plug.Builder
  plug(:confirmed)

  def read_bod (conn) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    body
  end

  @spec confirmed(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def confirmed(conn, _) do

    body_par = case conn.body_params do
       %Plug.Conn.Unfetched{} -> read_bod(conn)
        other -> other
    end
    |> Jason.decode!()
    |> Map.new()

    case Uptight.Result.new( fn ->
      require Logger
      Logger.warn(body_par)
      %{"issuer" => publickey} = body_par
      #Logger.warn(publickey_raw)
      #publickey = Uptight.Base.mk_url!(publickey_raw)
      Logger.warn(publickey)
      pid = DoAuth.User.by_publickey!(publickey)
      Logger.warn(pid)
    end) do
      %Uptight.Result.Ok{} -> send_resp(conn, 200, "user is logged")
      %Uptight.Result.Err{err: err} -> send_resp(conn, 404, %{error: "User don't login", details: err} |> Jason.encode!()) |> Plug.Conn.halt()
    end

  end

end
