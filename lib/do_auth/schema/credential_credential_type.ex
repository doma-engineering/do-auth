defmodule DoAuth.Schema.CredentialCredentialType do
  use DoAuth.Boilerplate.DatabaseStuff

  @primary_key false
  schema "credentials_credential_types" do
    belongs_to(:credential_type, CredentialType)
    belongs_to(:credential, Credential)
  end
end
