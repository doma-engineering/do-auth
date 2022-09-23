defmodule DoAuth.Router do
  @moduledoc """
  DO NOT USE IN PRODUCTION!
  This router is only there for standalone tests.
  DO NOT USE IN PRODUCTION!
  """
  use Plug.Router

  plug(:match)
  plug(CORSPlug)
  plug(Plug.Logger, log: :debug)
  plug(:dispatch)

  get "/doauth/confirm" do
    Plug.run(conn, [{DoAuth.Web.Confirm, []}])
  end

  get "/doauth/reserve" do
    Plug.run(conn, [
      {DoAuth.Web.Reserve, []}
    ])
  end

  post "/echo" do
    Plug.run(conn, [{DoAuth.Web.Echo, []}])
  end

  match _ do
    send_resp(conn, 404, "Oopsie")
  end
end
