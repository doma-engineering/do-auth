defmodule DoAuth.Chappy.Invite do
  @moduledoc """
  This module is dedicated to sending out invites and stuff.
  """

  use Phoenix.Controller, namespace: DoAuth.Web

  alias DoAuth.Chappy.InviteView, as: View
  alias DoAuth.Invite
  alias DoAuth.Credential
  alias DoAuth.Repo
  alias DoAuth.DID
  alias DoAuth.Crypto

  def init(x), do: x

  def fulfill_and_grant(c, _) do
    {:ok, {fulfillment, grant}} =
      Repo.transaction(fn ->
        invite =
          Map.get(c.body_params, "invite", "{}")
          # TODO: This keys: :atoms bit should seriously be moved into some convenience function. It's very error-prone
          |> Jason.decode!(keys: :atoms)

        pk64 = Map.get(c.body_params, "publicKey", "")
        %{public: spk} = Crypto.server_keypair()

        true = Credential.verify_map(invite, spk)

        # TODO: make this `from_new_pk64` API just a tad less horrible
        {:ok, %{insert_did: did}} = DID.from_new_pk64(pk64, %{}) |> Repo.transaction()
        fulfillment = Invite.fulfill_map(pk64, invite)
        grant = Invite.grant(did |> Repo.preload(:key), 2)

        {fulfillment, grant}
      end)

    c |> put_view(View) |> render("fulfill.json", %{fulfillment: fulfillment, grant: grant})
  end
end
