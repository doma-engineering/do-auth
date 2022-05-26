defmodule DoAuth.InviteTest do
  alias Uptight.Base, as: B

  @moduledoc """
  Tests of invite logic and that authed endpoints work
  """
  use Plug.Test
  use ExUnit.Case, async: false

  use DoAuth.TestFixtures, [:crypto]
  alias DoAuth.{Crypto, Invite}
  alias Uptight.Result

  test "root invitations can be granted" do
    # IO.inspect("ROOT INVITATIONS TEST START")
    granted = Invite.grant_root_invite() |> Result.from_ok()
    assert Crypto.verify_map(granted) |> Result.is_ok?()
    assert Crypto.verify_map(granted["verifiableCredential"]) |> Result.is_ok?()
    # IO.inspect("ROOT INVITATIONS TEST END")
  end

  test "root invites can be fulfilled and cannot be reused" do
    # IO.inspect("FULFILL TEST START")
    granted = Invite.grant_root_invite() |> Result.from_ok()
    kp1 = signing_key_fixture(Enum.random(1..4)) |> map(&B.safe!/1)
    fulfilled = Invite.fulfill(kp1[:public], granted) |> Result.from_ok()
    assert Crypto.verify_map(fulfilled) |> Result.is_ok?()
    assert Invite.lookup(kp1[:public]) == fulfilled
    # IO.inspect("FULFILL TEST END")
    # IO.inspect("REUSE TEST START")
    granted = Invite.grant_root_invite() |> Result.from_ok()

    sig_granted = granted["proof"]["signature"]
    sig_root_invite = granted["verifiableCredential"]["proof"]["signature"]

    fulfs = GenServer.call(DoAuth.Invite, {:get_fulfillments, sig_root_invite})
    assert 0 < fulfs |> Enum.count()
    fulfs = GenServer.call(DoAuth.Invite, {:get_fulfillments, sig_granted})
    assert 0 == fulfs |> Enum.count()

    kp1 = signing_key_fixture(14) |> map(&B.safe!/1)
    kp2 = signing_key_fixture(15) |> map(&B.safe!/1)
    # Fulfill me once, shame on me...
    _fulfilled = Invite.fulfill(kp1[:public], granted) |> Result.from_ok()

    fulfs = GenServer.call(DoAuth.Invite, {:get_fulfillments, sig_granted})
    assert 1 == fulfs |> Enum.count()

    # But you can't fulfill me twice. It's just not how it works.
    fulfilled2 = Invite.fulfill(kp2[:public], granted)
    assert fulfilled2 |> Result.is_err?()
    # IO.inspect("REUSE TEST END")
  end
end
