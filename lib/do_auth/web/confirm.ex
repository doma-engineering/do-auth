defmodule DoAuth.Web.Confirm do
  @moduledoc """
  A plug used to confirm the users' registration.
  """

  use Plug.Builder

  import Uptight.Assertions

  alias Uptight.Text, as: T
  alias Uptight.Result
  alias Uptight.Trace
  alias DoAuth.User
  alias DoAuth.Credential

  plug(:confirm)
  plug(:render_result)

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
           %User{email: _reg_email, cred_id: cred_id} = User.get_state!(email)
           cred = Credential.tip(cred_id)

           assert cget.(cred, "kind") != "approved", "Submitted email already approved."

           assert cget.(cred, "secret") == token_raw,
                  "Token is deferent as shared secret, recorded by the server."

           assert DateTime.compare(Tau.from_raw_utc_iso8601!(cred["validUntil"]), Tau.now()) ==
                    :gt,
                  "Approving term is out."

           User.approve_confirmation!(email, opts)
         end) do
      %Result.Ok{} ->
        assign_result(conn, :success, "E-mail success approved" |> Jason.encode!())

      %Result.Err{err: err} ->
        case err do
          %Trace{exception: %Uptight.AssertionError{message: "Submitted email already approved."}} ->
            assign_result(conn, :success, "Submitted email already approved." |> Jason.encode!())

          %Trace{exception: %Uptight.AssertionError{message: "Approving term is out."}} ->
            assign_result(conn, :error, 404, "Approving term is out." |> Jason.encode!())

          %Trace{
            exception: %Uptight.AssertionError{
              message: "Token is deferent as shared secret, recorded by the server."
            }
          } ->
            assign_result(
              conn,
              :error,
              "Token is deferent as shared secret, recorded by the server." |> Jason.encode!()
            )

          _ ->
            assign_result(conn, :error, err |> Jason.encode!())
        end
    end
  end

  @spec assign_result(Plug.Conn.t(), atom(), nil | non_neg_integer(), any()) :: Plug.Conn.t()
  defp assign_result(conn, :success, status, message) do
    conn
    |> assign(:is_registration_successful, true)
    |> Plug.Conn.put_status(status)
    |> assign(:message, message)
  end

  defp assign_result(conn, :error, status, error) do
    conn
    |> assign(:is_registration_successful, false)
    |> Plug.Conn.put_status(status)
    |> assign(:error, error)
  end

  defp assign_result(conn, atom, output) do
    case atom do
      :success -> assign_result(conn, :success, 200, output)
      :error -> assign_result(conn, :error, 403, output)
    end
  end

  def render_result(conn, _) do
    if conn.assigns.is_registration_successful do
      send_resp(conn, conn.status, conn.assigns.message)
    else
      send_resp(conn, conn.status, conn.assigns.error)
    end
  end
end
