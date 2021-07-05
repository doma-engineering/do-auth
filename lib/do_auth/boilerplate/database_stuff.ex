defmodule DoAuth.Boilerplate.DatabaseStuff do
  @moduledoc """
  Alias stuff that's related to the DB.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import Ecto.Changeset
      import Ecto.Query, only: [from: 2]

      alias DoAuth.Repo
      alias Ecto.Schema
      alias Ecto.Changeset
      alias Ecto.Multi

      alias DoAuth.Schema.{
        Credential,
        DID,
        Issuer,
        Key,
        Proof,
        Subject,
        URL,
        Context,
        CredentialContext,
        CredentialType,
        CredentialCredentialType,
        ProofType,
        # TODO: We have Authentication purpose, but also now we have AntiTamper
        # purpose. Probably should encode them at some point.
        ProofPurpose
      }
    end
  end
end
