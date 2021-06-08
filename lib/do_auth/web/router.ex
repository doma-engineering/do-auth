defmodule DoAuth.Web.Router do
  @moduledoc """
  Phoenix router, describing the entirety of DoAuth API.
  """
  use Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :chappy do
    plug(:accepts, ["json"])
    plug(:fetch_session)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(DoAuth.Chappy.Chappy)
  end

  scope "/", DoAuth do
    pipe_through(:browser)
    get("/", ZeroVC.ZeroVC, :index)
    get("/demo", ZeroVC.ZeroVC, :demo)
    get("/hello/world", ZeroVC.ZeroVC, :cheer)
  end

  scope "/chappy", DoAuth do
    pipe_through(:chappy)
    get("/", Chappy.Chappy, :the_endpoint)
    get("/tofu", Chappy.Tofu, :me)
    post("/invite", Chappy.Invite, :fulfill_and_grant)
  end

  scope "/api", DoAuth do
    pipe_through(:api)
    get("/chappy/demo", Chappy.Chappy, :the_endpoint)
  end
end
