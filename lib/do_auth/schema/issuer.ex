defmodule DoAuth.Schema.Issuer do
  @moduledoc """
  Issuer is either an URL or a DID.
  """
  use DoAuth.Boilerplate.DatabaseStuff

  schema "issuers" do
    belongs_to(:did, DID)
    belongs_to(:url, URL)
    has_many(:proofs, Proof, foreign_key: :verification_method_id)
  end

  def build_preload() do
    [:url, [did: :key]]
  end

  @spec build_by_did_id(pos_integer()) :: Ecto.Query.t()
  def build_by_did_id(did_id) do
    from(i in __MODULE__, where: i.did_id == ^did_id)
  end

  @spec all_by_did_id(pos_integer()) :: list(%__MODULE__{})
  def all_by_did_id(did_id) do
    build_by_did_id(did_id) |> Repo.all() |> preload()
  end

  @spec from_did_schema(%DID{}) :: {:ok, %__MODULE__{}} | {:error, any()}
  def from_did_schema(%DID{} = did) do
    build_from_did(did) |> Repo.insert() |> preload()
  end

  @spec from_did_schema!(%DID{}) :: %__MODULE__{}
  def from_did_schema!(%DID{} = did) do
    {:ok, issuer} = from_did_schema(did)
    issuer
  end

  @spec build_from_did(any) :: Ecto.Changeset.t()
  def build_from_did(did), do: changeset(%{"did" => did})
  @spec build_from_url(any) :: Ecto.Changeset.t()
  def build_from_url(url), do: changeset(%{"url" => url})

  @spec changeset(nil | keyword | map) :: Ecto.Changeset.t()
  def changeset(stuff) do
    with result <-
           (if stuff["did"] do
              Ecto.build_assoc(stuff["did"], :issuer)
            else
              Ecto.build_assoc(stuff["url"], :issuer)
            end) do
      dummy_schema = %{did: :integer, url: :integer}
      ids = stuff |> Enum.map(fn {k, v} -> {k, Map.get(v, :id)} end) |> Enum.into(%{})

      dummy_changeset =
        {%{}, dummy_schema}
        |> cast(ids, Map.keys(dummy_schema))
        |> DoAuth.Repo.validate_xor(Map.keys(dummy_schema))

      if dummy_changeset.valid? do
        result |> change()
      else
        dummy_changeset
      end
    end
  end

  @spec preload(%__MODULE__{}) :: %__MODULE__{} | {:ok, %__MODULE__{}} | [%__MODULE__{}]
  def preload({:ok, issuer = %__MODULE__{}}) do
    {:ok, preload(issuer)}
  end

  def preload(issuer_data) do
    issuer_data |> Repo.preload(build_preload())
  end

  def to_string(%__MODULE__{url_id: nil, did: did = %DID{}}) do
    did = Repo.preload(did, :key)
    DID.to_string(did)
  end

  def to_string(%__MODULE__{did_id: nil, url_id: url = %URL{}}) do
    url |> URL.to_string()
  end

  def to_map(issuer, opts \\ [])

  def to_map(%__MODULE__{url_id: nil, did: did = %DID{}}, opts) do
    did |> Repo.preload(:key) |> DID.to_map(opts)
  end

  def to_map(%__MODULE__{did_id: nil, url: url = %URL{}}, opts) do
    url |> URL.to_map(opts)
  end
end
