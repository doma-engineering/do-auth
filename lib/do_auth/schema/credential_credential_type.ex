defmodule DoAuth.Schema.CredentialCredentialType do
  @moduledoc """
  A human-readable counterparts of contexts. For instance
  => https://www.w3.org/2018/credentials/examples/v1 this context
  shall have human-readable representation of "AlumniCredential".

  Then @context's and type's can be zipped together for human-readable rendering.
  Yes, this is a dubious standard design, maybe it's there for backwards compatibility reasons?

  Nonetheless, as DoAuth increases standard compliance, contexts and credential types should be merged into one table and one Ecto schema.
  """
  use DoAuth.Boilerplate.DatabaseStuff

  @primary_key false
  schema "credentials_credential_types" do
    belongs_to(:credential_type, CredentialType)
    belongs_to(:credential, Credential)
  end
end
