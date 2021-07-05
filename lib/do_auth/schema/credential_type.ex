defmodule DoAuth.Schema.CredentialType do
  @moduledoc """
  Different credential types that are allowed for credentials hosted on this server.
  """
  use DoAuth.Boilerplate.DatabaseStuff

  schema "credential_types" do
    field(:type, :string)

    has_many(:credentials_credential_types, CredentialCredentialType,
      foreign_key: :credential_type_id
    )
  end
end
