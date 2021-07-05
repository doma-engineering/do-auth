defmodule DoAuthWeb.PageController do
  use DoAuthWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
