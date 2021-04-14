defmodule DoAuth.CredentialContext do
  use DoAuth.DBUtils, into: __MODULE__

  @primary_key false
  schema "credentials_contexts" do
    belongs_to(:context, DoAuth.Context)
    belongs_to(:credential, DoAuth.Context)
  end

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    DBUtils.castreq(c, stuff, [:context, :credential])
  end

  DBUtils.codegen(into: __MODULE__)
end

############

defmodule DoAuth.CredentialCredentialType do
  use DoAuth.DBUtils, into: __MODULE__

  @primary_key false
  schema "credentials_credential_types" do
    belongs_to(:credential_type, DoAuth.Context)
    belongs_to(:credential, DoAuth.Context)
  end

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    DBUtils.castreq(c, stuff, [:credential_type, :credential])
  end

  DBUtils.codegen(into: __MODULE__)
end
