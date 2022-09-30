defmodule DoAuth.Web.ConfirmTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias DoAuth.Credential
  alias DoAuth.User
  alias Uptight.Result
  alias Uptight.Text, as: T

  describe "DoAuth.Web.Confirm Plug" do
    setup do
      email = T.new!("user2@mail.com")
      nickname = T.new!("user")

      %{
        email: email,
        nickname: nickname,
        fopts: fn -> [no_mail: true, validUntil: Tau.now() |> DateTime.add(700, :millisecond)] end
      }
    end

    test "with invalid token - render error" do
      conn =
        conn(:get, "/doauth/confirm", %{email: "example@email.com", token: ""})
        |> DoAuth.Router.call([])

      assert conn.status == 403
    end

    test "with previously reserved identity and matched credentials - returns success message", %{
      email: email,
      nickname: nickname
    } do
      pid = User.reserve_identity(email, nickname) |> Result.from_ok()
      %{cred_id: %Uptight.Base.Urlsafe{} = cred_id} = User.get_state!(pid)
      secret = Credential.tip(cred_id) |> extract_secret()

      conn =
        conn(:get, "/doauth/confirm", %{email: email.text, token: secret})
        |> DoAuth.Router.call([])

      assert conn.status == 200
    end

    defp extract_secret(confirmation_cred),
      do: confirmation_cred |> Kernel.get_in(["credentialSubject", "secret"])
  end
end
