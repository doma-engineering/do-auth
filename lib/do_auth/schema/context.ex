defmodule DoAuth.Schema.Context do
  @moduledoc """
  Different contexts that are allowed for credentials hosted on this server.
  """
  use DoAuth.Boilerplate.DatabaseStuff

  schema "contexts" do
    field(:context, :string)
    has_many(:credentials_contexts, CredentialContext, foreign_key: :context_id)
  end
end
