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

  # TODO: stuff like this ``Repo.one'' can and will break high availability
  # version with cross-data-center replication. By not addressing this issue
  # head on we're accumulating technical debt.
  def by_claim_me(self_assigned_identifier) do
    from(c in __MODULE__, where: c.claim["me"] == ^self_assigned_identifier) |> Repo.one()
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
