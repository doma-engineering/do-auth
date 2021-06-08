defmodule DoAuth.Invite do
  @moduledoc """
  Functions to make invites.
  So far, it supports number-bound invites.

  To preserve privacy, when an invite is accepted and client certificate is
  generated, a server-signed credential get issued that effectively reduces the
  "invite issued" count.
  """

  alias DoAuth.Repo
  alias DoAuth.Crypto
  alias DoAuth.Subject
  alias DoAuth.DID
  alias DoAuth.Key
  alias DoAuth.Credential

  import Ecto.Query, only: [from: 2]

  @spec grant(%DID{}, pos_integer()) :: %Credential{}
  def grant(did = %DID{}, n) do
    Credential.tx_from_keypair_credential!(
      Crypto.server_keypair(),
      %{
        kind: "invite",
        capacity: n,
        holder: DID.show(did)
      },
      %{
        location:
          "/invites/" <>
            Crypto.salted_hash(
              ~s(invite|#{inspect(n)}|#{DID.show(did)}|#{inspect(DateTime.utc_now())})
            )
      }
    )
    |> Repo.preload(Credential.preload_credential())
  end

  defp fulfill_zero(pk64, invite) do
    did_stored = DID.by_pk64(pk64) |> Repo.one!() |> Repo.preload(:key)

    Credential.tx_from_keypair_credential!(Crypto.server_keypair(), %{
      parent: invite.misc["location"],
      holder: did_stored |> DID.show(),
      kind: "fulfill"
    })
  end

  defp fulfill_zero_map(pk64, invite) do
    did_stored = DID.by_pk64(pk64) |> Repo.one!() |> Repo.preload(:key)

    Credential.tx_from_keypair_credential!(Crypto.server_keypair(), %{
      parent: invite[:credentialSubject][:misc][:id],
      holder: did_stored |> DID.show(),
      kind: "fulfill"
    })
  end

  @doc """
  Map version of fulfill.
  """
  def fulfill_map(pk64, invite = %{}, mk_cred \\ &fulfill_zero_map(&1, &2)) do
    {:ok, cred} =
      Repo.transaction(fn ->
        # TODO: Repo.one!() is jeopardising high availability set ups where we don't
        # guaranntee singularity of DID <-> Key relationships

        key = invite[:issuer] |> DID.read() |> Key.by_did() |> Repo.one!()

        {_, true} =
          {invite, Credential.verify_map(invite, key.public_key |> Crypto.read!())}
          |> is_fresh()
          |> is_vacant()

        _cred =
          Credential.tx_from_keypair_credential!(Crypto.server_keypair(), %{
            parent: invite[:id],
            kind: "decrement"
          })

        # TODO: Should this sinful stuff be a function?
        pk_stored =
          case pk64 |> Key.by_pk() |> Repo.all() do
            [] ->
              Key.changeset(%{public_key: pk64}) |> Repo.insert!()

            [x = %DoAuth.Key{}] ->
              x
          end

        _did_stored =
          case DID.by_pk64(pk64) |> Repo.all() do
            [] ->
              DoAuth.DID.from_key(pk_stored) |> Repo.insert!()

            [x = %DoAuth.DID{}] ->
              x
          end

        mk_cred.(pk64, invite)
      end)

    cred
  end

  @doc """
  Checks that invite is valid and still has slots.
  Creates two things: a credential, issued by the server, that links back to the
  grant credential that serves as a downtick for the counter and a credential
  for the new DID to join the network.
  """
  def fulfill(pk64, invite = %Credential{}, mk_cred \\ &fulfill_zero(&1, &2)) do
    {:ok, cred} =
      Repo.transaction(fn ->
        # TODO: Repo.one!() is jeopardising high availability set ups where we don't
        # guaranntee singularity of DID <-> Key relationships
        key =
          invite.issuer
          |> Repo.preload(Credential.preload_entity())
          |> Map.get(:did)
          # |> DID.read()
          |> Key.by_did()
          |> Repo.one!()

        {_, true} =
          {invite, Credential.verify(invite, key.public_key |> Crypto.read!())}
          |> is_fresh()
          |> is_vacant()

        _cred =
          Credential.tx_from_keypair_credential!(Crypto.server_keypair(), %{
            parent: invite.misc["location"],
            kind: "decrement"
          })

        # TODO: Should this sinful stuff be a function?
        pk_stored =
          case pk64 |> Key.by_pk() |> Repo.all() do
            [] ->
              Key.changeset(%{public_key: pk64}) |> Repo.insert!()

            [x = %DoAuth.DID{}] ->
              x
          end

        _did_stored =
          case DID.by_pk64(pk64) |> Repo.all() do
            [] ->
              DoAuth.DID.from_key(pk_stored) |> Repo.insert!()

            [x = %DoAuth.DID{}] ->
              x
          end

        mk_cred.(pk64, invite)
      end)

    cred
  end

  defp is_fresh({err, false}), do: {err, false}

  # TODO: Check for expiration
  defp is_fresh({i, true}), do: {i, true}

  defp is_vacant({err, false}), do: {err, false}

  defp is_vacant({i, true}) do
    parent_id =
      case i do
        %Credential{} -> i.misc["location"]
        _ -> i[:id]
      end

    # case(from(c in Subject, where: fragment(~s(? ->> 'parent': ))))
    fulfilled =
      from(s in Subject,
        where:
          fragment(~s(? ->> 'parent' = ?), s.claim, ^parent_id) and
            fragment(~s(? ->> 'kind' = ?), s.claim, "decrement")
      )
      |> Repo.aggregate(:count)

    # TODO: REMOVE THIS WORKAROUND! CONVERGE EXTERNAL (MAP) CREDS AND INTERNAL ECTO CREDS!
    capacity =
      case i do
        %Credential{} ->
          i |> Repo.preload(Credential.preload_credential())
          i.subject.claim["capacity"]

        _ ->
          i[:credentialSubject][:count]
      end

    if capacity > fulfilled do
      {i, true}
    else
      {"Invite is over capacity", false}
    end
  end
end
