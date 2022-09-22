defmodule DoAuth.Web.Confirm do
  @moduledoc """
  A plug used to confirm the users' registration.
  """

  use Plug.Builder

  import Uptight.Assertions

  alias Uptight.Text, as: T
  alias Uptight.Result
  alias DoAuth.User
  alias DoAuth.Credential

  plug :confirm
  plug :render_result

  @doc """
  Options:

   :reasons -- list of texts
  """
  @spec confirm(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def confirm(conn, opts) do
    # Force query param parsing
    conn =
      case conn.query_params do
        %Plug.Conn.Unfetched{} -> Plug.Conn.fetch_query_params(conn)
        _otherwise -> conn
      end

    cget = fn cred, x -> cred["credentialSubject"][x] end

    case Result.new(fn ->
           %{"email" => email_raw, "token" => token_raw} = conn.query_params
           email = email_raw |> T.new!()
           %User{email: _reg_email, cred: cred_id} = User.get_state!(email)
           cred = Credential.tip(cred_id)

           assert cget.(cred, "secret") == token_raw,
                  "User-submitted token is the same as shared secret, recorded by the server."

           User.approve_confirmation!(email, opts)
         end) do
        x -> assign_result(conn, x)
    end
  end

  defp assign_result(conn, %Result.Ok{}) do
    conn
    |> assign(:is_registration_successful, true)
    |> assign(:message, "Identity confirmed successfully")
  end

  defp assign_result(conn, %Result.Err{}) do
    conn
    |> assign(:is_registration_successful, false)
    |> assign(:error, "Unauthorized")
  end

  def render_result(conn, _) do
    if conn.assigns.is_registration_successful do
      send_resp(conn, 200, conn.assigns.message)
    else
      send_resp(conn, 403, conn.assigns.error)
    end
  end
end
