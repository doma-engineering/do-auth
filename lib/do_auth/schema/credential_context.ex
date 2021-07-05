defmodule DoAuth.Schema.CredentialContext do
  use DoAuth.Boilerplate.DatabaseStuff

  @primary_key false
  schema "credentials_contexts" do
    belongs_to(:credential, Credential)
    belongs_to(:context, Context)
  end
end
