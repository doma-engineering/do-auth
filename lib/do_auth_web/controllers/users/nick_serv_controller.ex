defmodule DoAuthWeb.Users.NickServController do
  @moduledoc """
  A simplistic approach to alias registrations.
  Think libera NickServ, but ten years ago :)
  """

  use DoAuthWeb, :controller
  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.NickServ
  alias DoAuthWeb.Users.NickServView, as: View
  import DoAuth.Cat, only: [cont: 2]

  action_fallback DoAuthWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, %{"register" => req_map}) do
    conn = conn |> put_view(View)

    try do
      case NickServ.register64(req_map) do
        {:ok, cred} ->
          conn |> render("index.json", %{fulfillment: cred |> Credential.to_map()})

        e = {:error, _} ->
          conn |> put_status(403) |> render("403.json", %{"error" => e})
      end
    rescue
      _e ->
        conn
        |> put_status(403)
        |> render("403.json", %{"error" => "invalid data"})
    end
  end

  def index(conn, _) do
    missing_required_data(conn)
  end

  @spec whois(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def whois(conn, %{"did" => did_str}) do
    conn = conn |> put_view(View)

    nickname_maybe = did_str |> NickServ.whois_did64()

    case nickname_maybe do
      {:ok, nickname} ->
        conn |> render("whois.json", %{"nickname" => nickname})

      e = {:error, _} ->
        conn |> put_status(404) |> render("404.json", %{"error" => e})
    end
  end

  def whois(conn, %{"nickname" => nickname}) do
    conn = conn |> put_view(View)

    case nickname
         |> NickServ.is_valid_nickname()
         |> cont(fn -> NickServ.whois_nickname(nickname) end) do
      {:ok, did_str} ->
        conn |> render("whois.json", %{"did" => did_str})

      e = {:error, _} ->
        conn |> put_status(404) |> render("404.json", %{"error" => e})
    end
  end

  def whois(conn, _) do
    missing_required_data(conn)
  end

  defp missing_required_data(conn) do
    conn
    |> put_view(View)
    |> put_status(403)
    |> render("403.json", %{"error" => "missing required data"})
  end
end
