defmodule DoAuth.Schema.CredentialContext do
  @moduledoc """
  Contexts are used in VCDM for feature / capability discovery.
  At some point, we'll start supporting third party contexts and lay claim on ours.
  """
  use DoAuth.Boilerplate.DatabaseStuff

  @primary_key false
  schema "credentials_contexts" do
    belongs_to(:credential, Credential)
    belongs_to(:context, Context)
  end
end
