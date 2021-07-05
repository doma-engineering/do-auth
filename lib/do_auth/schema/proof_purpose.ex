defmodule DoAuth.Schema.ProofPurpose do
  @moduledoc """
  Supported proof purposes. (See VC standard for non-normative description).
  """
  use DoAuth.Boilerplate.DatabaseStuff

  schema "proof_purposes" do
    field(:purpose, :string)
    field(:misc, :map)
  end
end
