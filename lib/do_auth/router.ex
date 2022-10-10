defmodule DoAuth.Router do
  @moduledoc """
  DO NOT USE IN PRODUCTION!
  This router is only there for standalone tests.
  DO NOT USE IN PRODUCTION!
  """
  use Plug.Router

  plug(CORSPlug)
  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(Plug.Parsers, parsers: [:urlencoded, :json], pass: ["*/*"], json_decoder: Jason)

  plug(Plug.Static,
    at: "/",
    from: {:do_auth, "/priv/ui/build"}
  )

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
    priv_dir = :code.priv_dir(:do_auth)
    Plug.Conn.send_file(conn, 200, Path.join([priv_dir, "ui", "build", "index.html"]))
  end
end
