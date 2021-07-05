defmodule DoAuth.Schema.Key do
  @moduledoc """
  Key management schema.
  """
  use DoAuth.Boilerplate.DatabaseStuff

  schema "keys" do
    field(:public_key, :string)
    field(:purpose, :string)
    field(:misc, :map)
    has_many(:dids, DID)
  end

  @spec build_by_pk64(String.t()) :: Ecto.Query.t()
  def build_by_pk64(pk64) do
    from(k in __MODULE__, where: k.public_key == ^pk64)
  end

  @spec all_by_pk64(String.t()) :: __MODULE__.t()
  def all_by_pk64(pk64) do
    build_by_pk64(pk64) |> Repo.all()
  end

  @spec build_from_pk64(String.t()) :: Changeset.t()
  def build_from_pk64(pk64) do
    %{"public_key" => pk64} |> __MODULE__.changeset()
  end

  @spec from_pk64(String.t()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def from_pk64(pk64) do
    build_from_pk64(pk64) |> Repo.insert()
  end

  @spec from_pk64!(String.t()) :: %__MODULE__{}
  def from_pk64!(pk64) do
    build_from_pk64(pk64) |> Repo.insert!()
  end

  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(key_schema \\ %__MODULE__{}, third_party_data) do
    key_schema
    |> cast(third_party_data, [:public_key, :purpose])
    |> validate_required(:public_key)
  end
end
