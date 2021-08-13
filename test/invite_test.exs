defmodule InviteTest do
  use DoAuth.DataCase
  use DoAuth.Boilerplate.DatabaseStuff
  use DoAuth.Test.Support.Fixtures, [:crypto]
  alias DoAuth.{Crypto, Invite}
  alias DoAuth.Repo.Populate

  describe "Invite system is built such that" do
    setup do
      {:ok, _} = Populate.populate_do()
      :ok
    end

    test "invitations can be fulfilled" do
      kp = server_keypair_fixture()
      did = DID.one_by_pk!(kp.public)

      granted =
        Invite.grant!(did, 1, %{"effectiveDate" => Repo.now()},
          timestamp: Repo.now() |> DateTime.add(Enum.random(1..1_000_000))
        )

      invite = granted["verifiableCredential"]
      assert(Map.get(invite, "id", false))
      refute("/credential/cloaked" == invite["id"])

      new_kp = signing_key_fixture(Enum.random(8..32))
      new_pk64 = new_kp.public |> Crypto.show()
      {:ok, cred} = Invite.fulfill(new_pk64, granted)
      cred_map = cred |> Credential.to_map()
      assert("fulfill" == cred_map["credentialSubject"]["kind"])

      new_did = DID.one_by_pk64!(new_pk64)
      new_key = new_did.key |> Key.preload()
      assert(new_pk64 == new_key.public_key)
    end
  end
end
