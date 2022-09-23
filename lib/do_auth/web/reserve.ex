defmodule DoAuth.Web.Reserve do
  @moduledoc """
  A plug used to reserve the users' registration.
  """

  use Plug.Builder
  plug(:reserve)

  alias Uptight.Text, as: T
  alias Uptight.Result
  alias DoAuth.User

  @doc """
  Options:
    homebase:   frontend fqdn    T.t()
    port:       frontend port    T.t()
    front_name: frontend name    T.t()
    endpoint:   frontend confirm endpoint path     list(T.t())
  """
  @spec reserve(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def reserve(conn, _) do
    # Force query param parsing
    conn =
      case conn.query_params do
        %Plug.Conn.Unfetched{} -> Plug.Conn.fetch_query_params(conn)
        _otherwise -> conn
      end

    case Result.new(fn ->
           %{"email" => email_raw, "nickname" => nickname_raw} = conn.query_params
           email = email_raw |> T.new!()
           nickname = nickname_raw |> T.new!()
           opts = DoAuth.Web.default_opts()
           _pid = User.reserve_identity(email, nickname, opts) |> Result.from_ok()
         end) do
      %Result.Ok{} ->
        send_resp(conn, 200, "User successful reserved")

      %Result.Err{err: err} ->
        send_resp(conn, 403, %{error: "User reservation failed", details: err} |> Jason.encode!())
    end
    |> halt()
  end
end
