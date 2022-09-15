defmodule DoAuth.Web.Echo do
  @moduledoc """
  An echo plug, useful for debugging
  """
  use Plug.Builder
  plug(:echo)

  def get_body(conn) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    body
  end

  @spec echo(Plug.Conn.t(), any) :: Plug.Conn.t()
  def echo(conn, _) do
    require Logger

    send_resp(
      conn,
      200,
      %{
        assigns: conn.assigns,
        method: conn.method,
        params: conn.params,
        path_info: conn.path_info,
        path_params: conn.path_params,
        request_path: conn.request_path,
        query_string: conn.query_string,
        headers: conn.req_headers |> yeet_headers(),
        body: get_body(conn)
      }
      |> Jason.encode!()
    )

    # |> halt()
  end

  defp yeet_headers(hs) do
    Enum.map(hs, fn {k, v} -> "#{k}: #{v}" end)
  end
end
