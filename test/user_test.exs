defmodule DoAuth.UserTest do
  use ExUnit.Case

  alias Uptight.Result
  alias Uptight.Text, as: T
  alias DoAuth.User

  describe "reserve_identity/3" do
    setup do
      %Result.Ok{ok: email} = T.new("user@mail.com")
      %Result.Ok{ok: nickname} = T.new("user")

      on_exit(fn -> File.rm_rf!(Path.join(["db", "nonode@nohost"])) end)

      %{email: email, nickname: nickname}
    end

    test "with unused email allows to reserve identity", %{email: %T{text: email_text} = email, nickname: nickname} do
      %Result.Ok{ok: pid} = User.reserve_identity(email, nickname)

      assert is_pid(pid)

      assert %{
        email: ^email,
        nickname: ^nickname,
        cred: %Uptight.Base.Urlsafe{},
      } = :sys.get_state(pid)
    end

    test "with reserved identity - returns an error", ctx do
      User.reserve_identity(ctx.email, ctx.nickname)

      assert %Result.Err{err: %Uptight.Trace{
        exception: %Uptight.AssertionError{
          message: msg
        }}} = User.reserve_identity(ctx.email, ctx.nickname)

      assert msg == "The user with E-mail #{ctx.email.text} is already registered."
    end
  end
end
