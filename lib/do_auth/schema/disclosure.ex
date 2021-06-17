defmodule DoAuth.Disclosure do
  @moduledoc """
  A data structure representing an event of a user disclosing or revoking a
  disclosure of some credential.
  """
  use DoAuth.DBUtils, into: __MODULE__

  schema "disclosures" do
    belongs_to(:did, DoAuth.DID)
    belongs_to(:disclosure, DoAuth.Credential)
    field(:timestamp, :utc_datetime, read_after_writes: true)
  end

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    DBUtils.castreq(c, stuff, [:did, :disclosure])
  end

  DBUtils.codegen(into: __MODULE__)
end
