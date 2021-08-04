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

  @spec sin_one_pk(String.t()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def sin_one_pk(pk) do
    try do
      {:ok, sin_one_pk64!(pk |> Crypto.show())}
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
    end
  end

  @spec sin_one_pk!(String.t()) :: %__MODULE__{}
  def sin_one_pk!(pk) do
    {:ok, res} = sin_one_pk(pk)
    res
  end

  @spec sin_one_pk64(String.t()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def sin_one_pk64(pk64) do
    try do
      {:ok, sin_one_pk64!(pk64)}
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
    end
  end

  @spec sin_one_pk64!(String.t()) :: %__MODULE__{}
  def sin_one_pk64!(pk64) do
    {:ok, did} =
      Repo.transaction(fn ->
        pk_stored = Key.sin_one_pk64!(pk64)

        case DID.all_by_pk64(pk64) do
          [] ->
            DID.from_key_schema!(pk_stored)

          [x = %DID{}] ->
            x

          _ ->
            raise {"Expected at most one DID corresponding to pk64", pk64}
        end
      end)

    did |> preload()
  end

  @spec exists64(String.t()) :: boolean()
  def exists64(<<did64::binary>>) do
    0 < build_by_string(did64) |> Repo.all() |> length()
  end

  @spec to_map(%__MODULE__{}, list()) :: map()
  def to_map(did_schema, opts \\ [])

  def to_map(%__MODULE__{method: method, body: body, path: path}, format: :atom) do
    %{method: method, body: body, path: path}
  end

  def to_map(%__MODULE__{method: method, body: body, path: path}, _opts) do
    %{"method" => method, "body" => body, "path" => path}
  end

  @spec orphaned_from_string!(String.t()) :: %__MODULE__{}
  def orphaned_from_string!(did_str) do
    %URI{scheme: "did", path: method_body_path, query: _q, fragment: _frag} = URI.parse(did_str)
    [method, body_path] = method_body_path |> String.split(":")
    [body | path] = body_path |> String.split("/")

    path =
      case path do
        [] -> ""
        _ -> "/" <> Enum.join(path, "/")
      end

    %__MODULE__{method: method, body: body, path: path, misc: %{}}
  end

  @spec string_to_map!(String.t()) :: map()
  def string_to_map!(did_str), do: did_str |> orphaned_from_string!() |> to_map()

  @spec build_by_string(String.t()) :: Ecto.Query.t()
  def build_by_string(did_string) do
    try do
      did_string |> string_to_map!() |> build_by_map()
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
    end
  end

  @spec all_by_string(String.t()) :: [%__MODULE__{}]
  def all_by_string(did_string) do
    build_by_string(did_string) |> Repo.all() |> preload()
  end

  @spec build_by_map(map) :: Ecto.Query.t()
  def build_by_map(%{"method" => method, "body" => body, "path" => _path}) do
    from(q in build_by_body(body),
      # and
      where: q.method == ^method
      # (fragment("? = ?", q.path, ^path) or fragment("? = ?", q.path, nil))
    )
  end

  @spec all_by_map(map) :: %__MODULE__{}
  def all_by_map(did_map) do
    build_by_map(did_map) |> Repo.all() |> preload()
  end

  @spec build_by_body(String.t()) :: Ecto.Query.t()
  def build_by_body(body) do
    from(d in __MODULE__, where: d.body == ^body)
  end

  @spec all_by_body(String.t()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def all_by_body(body) do
    build_by_body(body) |> Repo.all() |> preload()
  end

  @spec one_by_body(String.t()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def one_by_body(body) do
    from(q in build_by_body(body), where: q.path == []) |> Repo.one() |> preload()
  end

  @spec one_by_body!(String.t()) :: %__MODULE__{}
  def one_by_body!(body) do
    {:ok, res} = one_by_body(body)
    res
  end

  @spec to_string(%DoAuth.Schema.DID{}) :: String.t()
  def to_string(%__MODULE__{} = did) do
    did |> to_map(format: :atom) |> DoAuth.URI.did2s()
  end

  @spec pk64_to_did_body(String.t()) :: String.t()
  def pk64_to_did_body(pk64) do
    pk64 |> Crypto.bland_hash()
  end

  @spec build_by_pk64(String.t()) :: Ecto.Query.t()
  def build_by_pk64(pk64) do
    from(d in __MODULE__, where: d.body == ^pk64_to_did_body(pk64))
  end

  @spec all_by_pk64(String.t()) :: [%__MODULE__{}]
  def all_by_pk64(pk64), do: build_by_pk64(pk64) |> Repo.all() |> preload()

  @spec one_by_pk64(String.t()) :: %__MODULE__{}
  def one_by_pk64(pk64), do: build_by_pk64(pk64) |> Repo.one() |> preload()

  @spec one_by_pk64!(String.t()) :: %__MODULE__{}
  def(one_by_pk64!(pk64), do: build_by_pk64(pk64) |> Repo.one!() |> preload())

  @spec one_by_pk(binary()) :: %__MODULE__{}
  def one_by_pk(pk), do: pk |> Crypto.show() |> one_by_pk64()

  @spec one_by_pk!(binary()) :: %__MODULE__{}
  def one_by_pk!(pk), do: pk |> Crypto.show() |> one_by_pk64!()

  @spec build_from_key_schema(%Key{}, map()) :: Changeset.t()
  def build_from_key_schema(key_schema, did_params \\ %{"method" => "doma"})

  def build_from_key_schema(%Key{} = key_schema, did_params) do
    result = Ecto.build_assoc(key_schema, :dids)
    result |> changeset(Map.put(did_params, "body", pk64_to_did_body(key_schema.public_key)))
  end

  @spec from_key_schema(%Key{}, map()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def from_key_schema(key_schema, did_params \\ %{"method" => "doma"})

  def from_key_schema(%Key{} = key_schema, %{} = did_params) do
    case build_from_key_schema(key_schema, did_params) |> Repo.insert() do
      {:ok, did} -> {:ok, did |> preload()}
      err -> err
    end
  end

  @spec from_key_schema!(%Key{}, map()) :: %__MODULE__{}
  def from_key_schema!(key_schema, did_params \\ %{"method" => "doma"})

  def from_key_schema!(%Key{} = key_schema, %{} = did_params) do
    {:ok, did} = from_key_schema(key_schema, did_params)
    did
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Changeset.t()
  def changeset(did, third_party_data) do
    did |> cast(third_party_data, [:method, :body]) |> validate_required(:body)
  end

  @spec build_preload() :: [:issuer | :key, ...]
  def build_preload() do
    [:key, :issuer]
  end

  @spec preload({:ok, %__MODULE__{}} | {:error, any()} | [%__MODULE__{}] | %__MODULE__{}) ::
          %__MODULE__{}
          | [%__MODULE__{}]
          | {:ok, %__MODULE__{} | [%__MODULE__{}]}
          | {:error, any()}
  def preload({:error, e}), do: {:error, e}
  def preload({:ok, did}), do: {:ok, preload(did)}

  def preload(dids) do
    dids |> Repo.preload(build_preload())
  end
end
