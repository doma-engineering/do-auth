defmodule DoAuth.Invite do
  @moduledoc """
  Functions to make invites.
  So far, it supports number-bound invites.

  When an invite is accepted and client certificate is generated, a server-signed credential get issued that effectively reduces the "invite issued" count.
  """

  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.{Crypto}

  @spec grant(%DID{}, pos_integer()) :: {:ok, %Credential{}} | {:error, any()}
  def grant(did, n) do
    try do
      {:ok, grant!(did, n)}
    rescue
      e -> {:error, e}
    end
  end

  @spec grant!(%DID{}, pos_integer()) :: %Credential{}
  def grant!(%DID{} = did, n) do
    Credential.transact_with_keypair_from_subject_map!(
      Crypto.server_keypair(),
      %{
        kind: "invite",
        capacity: n,
        holder: DID.to_string(did)
      },
      %{
        location:
          "/invites/" <>
            Crypto.salted_hash(
              ~s(invite|#{inspect(n)}|#{DID.to_string(did)}|#{inspect(DateTime.utc_now())})
            )
      }
    )
  end
end
