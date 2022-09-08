defmodule DoAuth.Web.Confirm do
  @moduledoc """
  A plug used to confirm the users' registration.
  """

  use Plug.Builder

  import Uptight.Assertions

  alias Uptight.Text, as: T
  alias Uptight.Result
  alias DoAuth.User

  plug(:confirm)

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

    case Result.new(fn ->
           %{"email" => email_raw, "token" => token_raw} = conn.query_params
           email = email_raw |> T.new!()
           %User{email: _reg_email, cred: cred} = User.get_state!(email)
           cget = fn x -> cred["credentialSubject"][x] end

           assert cget.("secret") == token_raw,
                  "User-submitted token is the same as shared secret, recorded by the server."

           User.approve_confirmation!(email, opts)
         end) do
      _x -> conn
    end
  end
end
