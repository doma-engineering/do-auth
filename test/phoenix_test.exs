defmodule PhoenixText do
  use DoAuth.Web.ConnCase
  use DoAuth.DBUtils

  alias DoAuth.Crypto
  alias DoAuth.Persistence
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
        Persistence.ensure_root_invite() |> Repo.preload(Credential.preload_credential())

      {m, _} = Crypto.main_key_init("in plain 5ight", DoAuthTest.very_weak_params())
      kp1 = Crypto.derive_signing_keypair(m, 1)
      %{public: pk1} = kp1
      %{public: pk2} = Crypto.derive_signing_keypair(m, 2)

      c =
        post(c, "/chappy/invite", %{
          publicKey: pk1 |> Crypto.show(),
          invite: invite |> Credential.to_map(unwrapped: true) |> Jason.encode!()
        })

      {_f1, invite2} = {c.assigns[:fulfillment], c.assigns[:grant]}

      #dbg_body = pk1 |> Crypto.show() |> Crypto.bland_hash()
      #did = from(d in DID, where: d.body == ^dbg_body) |> Repo.one!()

      invite2_map = invite2 |> Credential.to_map(unwrapped: true)

      # MatchError <- {{:issued_not_by_us_or_issued_by_us_but_held_by_someone_else, :issuer_is_not_the_holder, _}, false} =
      assert_raise(MatchError, fn ->
        post(c, "/chappy/invite", %{
          publicKey: pk2 |> Crypto.show(),
          invite: invite2_map |> Jason.encode!()
        })
      end)

      # TODO: Another confusing unwrapped: true bug that it took me some time to find

      # TODO: Change default behaviour to plain object, replace unwrapped: true
      # with tagged: true that would tag the resulting map with its type
      invite2_wrapped_map = Credential.tx_from_keypair_credential!(kp1, invite2_map) |> Credential.to_map(unwrapped: true)


      c = post(c, "/chappy/invite", %{
        publicKey: pk2 |> Crypto.show(),
        invite: invite2_wrapped_map |> Jason.encode!()
      })

      {_f2, _invite3} = {c.assigns[:fulfillment], c.assigns[:grant]}

      assert_raise(Ecto.ConstraintError, fn ->
        # Can't reuse wrapped invites!
        post(c, "/chappy/invite", %{
          publicKey: pk2 |> Crypto.show(),
          invite: invite2_wrapped_map |> Jason.encode!()
        })
      end)

      # TODO: Make use of f1, f2, invite2, invite3
      assert true
    end
  end
end
