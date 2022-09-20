defmodule DoAuth.UserTest do
  use ExUnit.Case, async: true
  use Bamboo.Test

  alias Uptight.Result
  alias Uptight.Text, as: T
  alias DoAuth.User
  alias DoAuth.Credential

  describe "reserve_identity/3" do
    setup do
      email = T.new!("user@mail.com")
      nickname = T.new!("user")

      %{
        email: email,
        nickname: nickname,
        fopts: fn -> [no_mail: true, validUntil: Tau.now() |> DateTime.add(700, :millisecond)] end
      }
    end

    test "with unused email allows to reserve identity once in a while",
         %{email: %T{text: email_raw} = email, nickname: nickname} = ctx do
      hostname = T.new!("do_auth.com")
      pid = User.reserve_identity(email, nickname, homebase: hostname) |> Result.from_ok()

      assert is_pid(pid)

      %{
        email: ^email,
        nickname: ^nickname,
        cred: %Uptight.Base.Urlsafe{} = cred_id
      } = :sys.get_state(pid)

      cred = Credential.tip(cred_id)

      t1 = Tau.from_raw_utc_iso8601!(cred["validUntil"])

      assert DateTime.compare(Tau.now() |> DateTime.add(User.reservation_seconds()), t1) == :gt,
             "Reservation shall eventually expire."

      # Removed assert here, it wasn't needed, because MatchError would explode first anyway.
      %{"credentialSubject" => %{"email" => ^email_raw}} = cred

      # That's a cute incidental e2e bit! At first I thought, maybe I'm not gonna send mail from tests, but I really like it.
      assert_email_delivered_with(subject: "Welcome to do_auth.com, #{nickname.text}!")

      # ExUnit seems to execute tests asynchronously even when async is set to false.
      # That's why we unify the two tests for reproducible test success!

      %Result.Err{
        err: %Uptight.Trace{
          exception: %Uptight.AssertionError{
            message: msg
          }
        }
      } = User.reserve_identity(ctx.email, ctx.nickname)

      # I'm not a *huge* fan of failing with messaging change,
      # but it's also OK in this case, because we make sure that the message can be relayed to frontend verbatim.
      assert msg == "E-Mail #{ctx.email.text} is still reserved."
    end

    test "there is a facility to invalidate a booked identity", ctx do
      sflip = &(T.un(&1) |> String.reverse() |> T.new!())
      email = ctx.email |> sflip.()
      name = ctx.nickname |> sflip.()

      _pid = User.reserve_identity(email, name, ctx.fopts.()) |> Result.from_ok()

      assert User.reserve_identity(email, name, ctx.fopts.()) |> Result.is_err?(),
             "If we double-reserve quickly, we still fail."

      :timer.sleep(700)

      pid2_maybe = User.reserve_identity(email, name, ctx.fopts.())

      assert pid2_maybe |> Result.is_ok?(),
             "Reservation expired, so we can reserve again against the same E-Mail"
    end
  end
end
