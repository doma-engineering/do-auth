defmodule DoAuth.Web.Router do
  @moduledoc """
  Phoenix router, describing the entirety of DoAuth API.
  """
  use Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:put_secure_browser_headers)
  end

  scope "/", DoAuth do
    pipe_through(:browser)
    get("/", ZeroVC.Controller, :index)
    get("/hello/world", ZeroVC.Controller, :cheer)
  end
end
