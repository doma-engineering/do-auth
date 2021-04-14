defmodule DoAuth.Key do
  @moduledoc """
  Key management schema.
  """
  use DoAuth.DBUtils, into: __MODULE__

  alias DoAuth.DID

  @typedoc """
  Map corresponding to Key schema.
  """
  @type mp :: %{
          required(:public_key) => String.t(),
          optional(:misc) => map(),
          optional(:purpose) => String.t()
        }

  schema "keys" do
    field(:public_key, :string)
    field(:purpose, :string)
    field(:misc, :map)
    has_many(:dids, DID)
  end

  def show(%__MODULE__{public_key: pk}), do: DoAuth.Crypto.show(pk)

  @doc """
  Query that retrieves a %Key{} by a serialised public key value.
  """
  @spec by_pk(String.t()) :: Ecto.Query.t()
  def by_pk(pk) do
    from(k in __MODULE__, where: k.public_key == ^pk)
  end

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    c |> cast(stuff, [:public_key, :misc, :purpose]) |> validate_required(:public_key)
  end

  DBUtils.codegen(into: __MODULE__, canonical_from_show: true)
end
