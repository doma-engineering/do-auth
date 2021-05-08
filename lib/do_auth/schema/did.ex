defmodule DoAuth.DID do
  @moduledoc """
  Ecto schema for libsodium PK hashed DIDs.
  """
  use DoAuth.DBUtils, into: __MODULE__
  alias DoAuth.Key
  alias DoAuth.Entity
  alias DoAuth.Crypto

  @typedoc """
  Map corresponding to DID schema.
  """
  @type mp :: %{
          optional(:method) => String.t(),
          optional(:path) => DoAuth.URI.path(),
          optional(:misc) => map(),
          required(:body) => String.t()
        }

  schema "dids" do
    field(:method, :string)
    field(:body, :string)
    field(:path, :map)
    belongs_to(:key, DoAuth.Key)
    field(:misc, :map)
    has_one(:entity, Entity)
  end

  @spec to_map(%__MODULE__{}, list()) :: map()
  def to_map(did = %__MODULE__{}, unwrapped: true) do
    %{
      method: did.method,
      body: did.body,
      public_key: did.key.public_key,
      path: did.path
    }
  end

  def to_map(x, []), do: to_map(x)
  def to_map(x), do: %{did: to_map(x, unwrapped: true)}

  # TODO: Is this enough of a reason to keep show/1?
  @spec show(%__MODULE__{}) :: String.t()
  def show(did = %__MODULE__{}) do
    did
    |> to_map(unwrapped: true)
    |> Map.delete(:public_key)
    |> DoAuth.URI.did2s()
  end

  @doc """
  Takes an existing URLSAFE Base64 public key and inserts a new DID derived from it.
  """
  @spec from_pk(%DoAuth.Key{}, mp()) :: Changeset.t()
  def from_pk(pk = %Key{}, didparams = %{}) do
    result = Ecto.build_assoc(pk, :dids)

    result
    |> changeset(Map.put(didparams, :body, hash(pk.public_key)))
  end

  @doc """
  Takes just the URLSAFE Base64 encoding of a public key (as opposed to a whole
  structure), and selects the DID derived from it.
  """
  @spec by_pk64(String.t()) :: Ecto.Query.t()
  def by_pk64(pk64) do
    from(d in __MODULE__,
      where: d.body == ^hash(pk64)
    )
  end

  @doc """
  Takes URLSAFE Base64 public key, inserts it and inserts a DID derived from it.
  """
  @spec from_new_pk64(String.t() | Key.mp(), mp()) :: Ecto.Multi.t()
  def from_new_pk64(pkparams = %{}, didparams = %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_key, Key.changeset(%Key{}, pkparams), mopts())
    |> Ecto.Multi.insert(:insert_did, &from_new_pk64_changeset(didparams).(&1), mopts())
  end

  def from_new_pk64(<<pk::binary>>, didparams) do
    from_new_pk64(%{public_key: pk}, didparams)
  end

  defp from_new_pk64_changeset(didparams) do
    fn %{insert_key: key} ->
      %__MODULE__{key_id: key.id, body: hash(key.public_key)} |> changeset(didparams)
    end
  end

  defp hash(x), do: Crypto.bland_hash(x)

  defp mopts(), do: [returning: true]

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    c |> cast(stuff, [:method, :body]) |> validate_required([:body, :key_id])
  end

  DBUtils.codegen(into: __MODULE__, canonical_from_show: true)
end
