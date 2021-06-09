defmodule NickServTest do
  use DoAuth.RepoCase
  use DoAuth.DBUtils
  alias DoAuth.NickServ
  alias DoAuth.Crypto
  alias DoAuth.Credential
  alias DoAuth.DID

  # TODO: Since we're speedrunning this shit, we're really ifgnoring the fact
  # that we need to actually sign registration request on client! It needs to be
  # fixed.

  test "nicknames can be registered locally" do
    DoAuth.Persistence.populate_do()
    kp = Crypto.server_keypair()

    {m, _} = Crypto.main_key_init("in plain 5ight", DoAuthTest.very_weak_params())
    %{public: pk1} = Crypto.derive_signing_keypair(m, 1)

    # TODO: This fucking `from_new_pk64` is the source of all the runtime bugs
    # during tested. This garbage interface should be fixed ASAP
    {:ok, %{insert_did: did}} = DID.from_new_pk64(pk1 |> Crypto.show(), %{}) |> Repo.transaction()

    assert_raise(MatchError, fn ->
      did |> Repo.preload(:key) |> NickServ.register("карн", false)
    end)

    {:ok, nickserv_cred_ecto} =
      did
      |> Repo.preload(:key)
      |> NickServ.register("libera_ted", false)

    nickserv_cred = nickserv_cred_ecto |> Credential.to_map(unwrapped: true)

    assert("/nickserv/libera_ted" == nickserv_cred.id)
    assert("libera_ted" == nickserv_cred.credentialSubject["nickname"])
    # TODO: ffs, this preload(:key) bullshit costed me half an hour of life by now
    assert(did |> Repo.preload(:key) |> DID.show() == nickserv_cred.credentialSubject["holder"])
    assert(Credential.verify_map(nickserv_cred, kp.public))
    assert(Credential.verify(nickserv_cred_ecto, kp.public))

    assert_raise(MatchError, fn ->
      did |> Repo.preload(:key) |> NickServ.register("urza", false)
    end)
  end
end
