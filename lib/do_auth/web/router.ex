defmodule DoAuth.Web.Router do
  @moduledoc """
  Phoenix router, describing the entirety of DoAuth API.
  """
  use Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_secure_browser_headers)
  end

  scope "/", DoAuth do
    pipe_through(:browser)
    get("/", ZeroVC.ZeroVC, :index)
    get("/hello/world", ZeroVC.ZeroVC, :cheer)
  end
end
