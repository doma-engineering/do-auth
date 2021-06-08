defmodule InviteTest do
  use DoAuth.RepoCase
  use DoAuth.DBUtils
  alias DoAuth.Crypto

  # alias DoAuth.Issuer
  alias DoAuth.DID
  # alias DoAuth.Entity
  # alias DoAuth.Subject
  alias DoAuth.Credential
  # alias DoAuth.Key
  alias DoAuth.Invite

  test "Invitations can be fulfilled" do
    DoAuth.Persistence.populate_do()
    kp = Crypto.server_keypair()
    did = kp.public |> Crypto.show() |> DID.by_pk64() |> Repo.one!() |> Repo.preload(:key)
    granted = Invite.grant(did, 1)
    granted_map = granted |> Credential.to_map(unwrapped: true)
    refute("/credential/cloaked" == granted_map.id)
    {mkey, _} = Crypto.main_key_init("password123", DoAuthTest.very_weak_params())
    new_kp = mkey |> Crypto.derive_signing_keypair(42)
    new_pk64 = new_kp.public |> Crypto.show()
    cred = Invite.fulfill(new_pk64, granted) |> Repo.preload(Credential.preload_credential())
    cred_map = cred |> Credential.to_map(unwrapped: true)
    # Logger.warn("#{inspect(cred_map)}")
    assert("/credential/cloaked" == cred_map.id)
    assert "fulfill" == cred.subject.claim["kind"]
    assert granted.misc["location"] == cred.subject.claim["parent"]
    assert Credential.verify(granted, kp.public)
    assert Credential.verify(cred, kp.public)
    # Now check that another fulfillment can't happen
    new_kp = mkey |> Crypto.derive_signing_keypair(42)
    new_pk64 = new_kp.public |> Crypto.show()

    catch_error(
      Invite.fulfill(new_pk64, granted)
      |> Repo.preload(Credential.preload_credential())
    )
  end
end
