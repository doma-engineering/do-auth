defmodule DoAuthWeb.Users.InviteController do
  @moduledoc """
  Accept or decline invites generated either by us, or by a user to whomst a right to invite is granted.
  """

  alias DoAuth.Invite
  use DoAuthWeb, :controller
  use DoAuth.Boilerplate.DatabaseStuff
  require Logger

  action_fallback DoAuthWeb.FallbackController

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, %{"public" => public, "presentation" => invite_presentation_map}) do
    conn = conn |> put_view(DoAuthWeb.Users.InviteView)

    # try do
    case Invite.fulfill(public, invite_presentation_map) do
      {:ok, fulfillment} ->
        conn
        |> render("index.json", %{fulfillment: fulfillment |> Credential.to_map()})

      {:error, e} ->
        error_map = stacktrace_to_error_list(e)

        Logger.warn(
          "Fulfillment error: #{inspect(e, pretty: true)}.\nSending error map: #{
            inspect(error_map, pretty: true)
          }"
        )

        conn |> put_status(403) |> render("403.json", error_map)
    end

    # rescue
    #   _e ->
    #     conn
    #     |> put_status(403)
    #     |> render("403.json", %{"error" => "invalid data"})
    # end
  end

  def index(conn, _) do
    conn
    |> put_status(403)
    |> put_view(DoAuthWeb.Users.InviteView)
    |> render("403.json", %{"both required" => ["public", "presentation"]})
  end

  defp stacktrace_to_error_list(e) do
    try do
      stacktrace = Map.get(e, "stack trace")

      legend = %{
        {DoAuth.Invite, :fulfill, 2, [file: 'lib/do_auth/invite.ex', line: 56]} =>
          "already registered"
      }

      %{
        "error" =>
          Enum.reduce(legend, [], fn {k, v}, acc ->
            if Enum.member?(stacktrace, k) do
              [v | acc]
            end
          end)
      }
    rescue
      _e ->
        %{"error" => "invite can't be fulfilled"}
    end
  end
end
