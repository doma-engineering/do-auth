defmodule DoAuth.Schema.ProofType do
  @moduledoc """
  Supported types of proofs. (See VC standard for non-normative description).
  """
  use DoAuth.Boilerplate.DatabaseStuff

  schema "proof_types" do
    field(:type, :string)
    field(:misc, :map)
  end
end
