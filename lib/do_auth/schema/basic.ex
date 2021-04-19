### https://www.youtube.com/watch?v=YQxopjai0CU

defmodule DoAuth.Subject do
  @moduledoc """
  Credential subjects are just free-form claims in DoAuth thus far.

  Management of obligatory fields is deferred to modules and systems using
  DoAuth to implement authentication and authorization protocols.
  """
  use DoAuth.DBUtils, into: __MODULE__

  schema "subjects" do
    field(:claim, :map)
    field(:misc, :map)
  end

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    c |> cast(stuff, [:claim, :misc]) |> validate_required(:claim)
  end

  def to_map(%__MODULE__{misc: nil, claim: c}, unwrapped: true) do
    c
  end

  def to_map(x, unwrapped: true) do
    x.claim |> Map.put_new(:misc, x.misc)
  end

  @spec to_map(atom | %{:claim => any, :misc => any, optional(any) => any}) :: %{claim: any}
  def to_map(x) do
    %{claim: to_map(x, unwrapped: true)}
  end

  DBUtils.codegen(into: __MODULE__, canonical_from_map: true)
end

############

defmodule DoAuth.ProofType do
  @moduledoc """
  Supported types of proofs. (See VC standard for non-normative description).
  """
  use DoAuth.DBUtils, into: __MODULE__

  schema "proof_types" do
    field(:type, :string)
    field(:misc, :map)
  end

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    c |> cast(stuff, [:type, :misc]) |> validate_required(:type)
  end

  DBUtils.codegen(into: __MODULE__)
end

############

defmodule DoAuth.ProofPurpose do
  @moduledoc """
  Supported proof purposes. (See VC standard for non-normative description).
  """
  use DoAuth.DBUtils, into: __MODULE__

  schema "proof_purposes" do
    field(:purpose, :string)
    field(:misc, :map)
  end

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    c |> cast(stuff, [:purpose, :misc]) |> validate_required(:purpose)
  end

  DBUtils.codegen(into: __MODULE__)
end

defmodule DoAuth.Context do
  @moduledoc """
  Different contexts that are allowed for credentials hosted on this server.
  """
  use DoAuth.DBUtils, into: __MODULE__

  schema "contexts" do
    field(:context, :string)
    has_many(:credentials_contexts, DoAuth.CredentialContext, foreign_key: :context_id)
  end

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    DBUtils.castreq(c, stuff, :context)
  end

  DBUtils.codegen(into: __MODULE__)
end

############

defmodule DoAuth.CredentialType do
  @moduledoc """
  Different credential types that are allowed for credentials hosted on this server.
  """
  use DoAuth.DBUtils, into: __MODULE__

  schema "credential_types" do
    field(:type, :string)

    has_many(:credentials_credential_types, DoAuth.CredentialCredentialType,
      foreign_key: :credential_type_id
    )
  end

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    DBUtils.castreq(c, stuff, :type)
  end

  DBUtils.codegen(into: __MODULE__)
end
