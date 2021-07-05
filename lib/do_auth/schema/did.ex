defmodule DoAuth.Schema.DID do
  @moduledoc """
  Ecto schema for libsodium PK-hashed DIDs.
  """

  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.{Crypto}

  schema "dids" do
    field(:method, :string)
    field(:body, :string)
    field(:path, :map)
    belongs_to(:key, Key)
    field(:misc, :map)
    has_one(:issuer, Issuer)
  end

  def to_map(did_schema, opts \\ [])

  def to_map(%__MODULE__{method: method, body: body, path: path}, format: :atom) do
    %{method: method, body: body, path: path}
  end

  def to_map(%__MODULE__{method: method, body: body, path: path}, _opts) do
    %{"method" => method, "body" => body, "path" => path}
  end

  @spec to_string(%DoAuth.Schema.DID{}) :: String.t()
  def to_string(%__MODULE__{} = did) do
    did |> to_map(format: :atom) |> DoAuth.URI.did2s()
  end

  @spec pk64_to_did_body(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | byte,
              binary | []
            )
        ) :: binary
  def pk64_to_did_body(pk64) do
    pk64 |> Crypto.bland_hash()
  end

  def build_by_pk64(pk64) do
    from(d in __MODULE__, where: d.body == ^pk64_to_did_body(pk64))
  end

  def all_by_pk64(pk64), do: build_by_pk64(pk64) |> Repo.all() |> preload()

  @spec one_by_pk64(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | byte,
              binary | []
            )
        ) :: nil | [%{optional(atom) => any}] | %{optional(atom) => any}
  def one_by_pk64(pk64), do: build_by_pk64(pk64) |> Repo.one() |> preload()
  def one_by_pk64!(pk64), do: build_by_pk64(pk64) |> Repo.one!() |> preload()
  def one_by_pk(pk), do: pk |> Crypto.show() |> one_by_pk64()
  def one_by_pk!(pk), do: pk |> Crypto.show() |> one_by_pk64!()

  def build_from_key_schema(key_schema, did_params \\ %{"method" => "doma"})

  def build_from_key_schema(%Key{} = key_schema, did_params) do
    result = Ecto.build_assoc(key_schema, :dids)
    result |> changeset(Map.put(did_params, "body", pk64_to_did_body(key_schema.public_key)))
  end

  def from_key_schema(key_schema, did_params \\ %{"method" => "doma"})

  def from_key_schema(%Key{} = key_schema, %{} = did_params) do
    case build_from_key_schema(key_schema, did_params) |> Repo.insert() do
      {:ok, did} -> {:ok, did |> preload()}
      err -> err
    end
  end

  def from_key_schema!(key_schema, did_params \\ %{"method" => "doma"})

  def from_key_schema!(%Key{} = key_schema, %{} = did_params) do
    {:ok, did} = from_key_schema(key_schema, did_params)
    did
  end

  def changeset(did, third_party_data) do
    did |> cast(third_party_data, [:method, :body]) |> validate_required(:body)
  end

  def build_preload() do
    [:key, :issuer]
  end

  def preload(dids) do
    dids |> Repo.preload(build_preload())
  end
end
