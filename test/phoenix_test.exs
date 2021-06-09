defmodule PhoenixText do
  use DoAuth.Web.ConnCase
  use DoAuth.DBUtils

  alias DoAuth.Crypto
  alias DoAuth.Persistence
  alias DoAuth.DID
  alias DoAuth.Credential

  describe "GET /" do
    test "ConnCase works", %{conn: c} do
      c = get(c, "/")
      assert 200 == c.status
    end
  end

  describe("POST /chappy/invite") do
    test "Can chain invites", %{conn: c} do
      Persistence.populate_do()

      invite =
        Persistence.ensure_root_invite(
          DID.by_pk64(Crypto.server_keypair()[:public] |> Crypto.show())
          |> Repo.one!()
          |> Repo.preload(:key)
        )
        |> Repo.preload(Credential.preload_credential())

      {m, _} = Crypto.main_key_init("in plain 5ight", DoAuthTest.very_weak_params())
      %{public: pk1} = Crypto.derive_signing_keypair(m, 1)
      %{public: pk2} = Crypto.derive_signing_keypair(m, 2)

      c =
        post(c, "/chappy/invite", %{
          publicKey: pk1 |> Crypto.show(),
          invite: invite |> Credential.to_map(unwrapped: true) |> Jason.encode!()
        })

      {_f1, invite2} = {c.assigns[:fulfillment], c.assigns[:grant]}

      c =
        post(c, "/chappy/invite", %{
          publicKey: pk2 |> Crypto.show(),
          invite: invite2 |> Credential.to_map(unwrapped: true) |> Jason.encode!()
        })

      {_f2, _invite3} = {c.assigns[:fulfillment], c.assigns[:grant]}

      # TODO: Make use of f1, f2, invite2, invite3
      assert true
    end
  end
end
