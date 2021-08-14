defmodule DoAuth.Schema.Proof do
  @moduledoc """
  Funcitons required to take a proofless credential and make it verifiable.
  """
  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.{Crypto, Cat}

  schema "proofs" do
    belongs_to(:verification_method, Issuer)
    field(:signature, :string)
    has_one(:credential, Credential)
    field(:timestamp, :utc_datetime, read_after_writes: true)
  end

  @spec to_map(%__MODULE__{}) :: map()
  def to_map(%__MODULE__{
        verification_method: verification_method,
        signature: signature,
        timestamp: timestamp
      }) do
    %{
      "verificationMethod" => Issuer.to_string(verification_method),
      "signature" => signature,
      "timestamp" => timestamp
    }
  end

  @spec canonical_sign!(Crypto.canonicalised_value(), Crypto.keypair()) :: Crypto.detached_sig()
  def canonical_sign!(canonical_term, kp) do
    {:ok, res} = canonical_sign(canonical_term, kp)
    res
  end

  @spec canonical_sign(Crypto.canonicalised_value(), Crypto.keypair()) ::
          {:ok, Crypto.detached_sig()} | {:error, any()}
  def canonical_sign(canonical_term, kp) do
    try do
      true = Crypto.is_canonicalised?(canonical_term)
      {:ok, canonical_term |> Jason.encode!() |> Crypto.sign(kp)}
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
    end
  end

  @spec canonical_sign64!(Crypto.canonicalised_value(), Crypto.keypair()) :: Crypto.detached_sig()
  def canonical_sign64!(canonical_term, kp64) do
    {:ok, res} = canonical_sign64(canonical_term, kp64)
    res
  end

  @spec canonical_sign64(Crypto.canonicalised_value(), Crypto.keypair()) ::
          {:ok, Crypto.detached_sig()} | {:error, any()}
  def canonical_sign64(canonical_term, kp64) do
    case Cat.fmap(kp64, &Crypto.show(&1)) do
      {:ok, kp} ->
        canonical_sign(canonical_term, kp)

      {:error, e} ->
        {:error, %{"failed to fmap Crypto.show onto kp64" => kp64, "error reported" => e}}
    end
  end

  @spec canonical_verify64(Crypto.canonicalised_value(), Crypto.detached_sig()) ::
          {:ok, boolean()} | {:error, any()}
  def canonical_verify64(canonicalised_value, detached_sig64) do
    try do
      true = Crypto.is_canonicalised?(canonicalised_value)

      {:ok,
       Crypto.verify(
         canonicalised_value |> Jason.encode!(),
         Cat.fmap!(detached_sig64, &Crypto.read!(&1))
       )}
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
    end
  end

  @spec canonical_verify64!(Crypto.canonicalised_value(), Crypto.detached_sig()) :: boolean()
  def canonical_verify64!(canonicalised_value, detached_sig64) do
    {:ok, res} = canonical_verify64(canonicalised_value, detached_sig64)
    res
  end

  @spec one_by_signature64(String.t()) :: nil | %__MODULE__{}
  def one_by_signature64(sig64) do
    build_by_signature64(sig64) |> Repo.one() |> preload()
  end

  @spec build_by_signature64(String.t()) :: Ecto.Query.t()
  def build_by_signature64(sig64) do
    from(p in __MODULE__, where: p.signature == ^sig64)
  end

  @spec from_signature64(%Issuer{}, String.t()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def from_signature64(issuer, sig64) do
    build_from_signature64(issuer, sig64) |> Repo.insert() |> preload()
  end

  @spec from_signature64!(%Issuer{}, String.t()) :: %__MODULE__{}
  def from_signature64!(issuer, sig64) do
    {:ok, sig} = from_signature64(issuer, sig64)
    sig
  end

  @spec build_from_signature64(%Issuer{}, String.t()) :: Ecto.Changeset.t()
  def build_from_signature64(issuer, sig64) do
    %{"signature" => sig64, "verification_method_id" => issuer.id} |> changeset()
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(proof_schema \\ %__MODULE__{}, third_party_data) do
    proof_schema
    |> cast(third_party_data, [:signature, :verification_method_id])
    |> validate_required([:signature, :verification_method_id])
  end

  @spec build_preload :: [
          :issuer | {:credential, [:contexts | :subject | :types | [...], ...]},
          ...
        ]
  def build_preload() do
    [verification_method: Issuer.build_preload(), credential: Credential.build_preload()]
  end

  @spec preload({:ok, %__MODULE__{}} | {:error, any()} | [%__MODULE__{}] | %__MODULE__{}) ::
          %__MODULE__{}
          | [%__MODULE__{}]
          | {:ok, %__MODULE__{} | [%__MODULE__{}]}
          | {:error, any()}
  def preload({:error, _} = e), do: e
  def preload({:ok, proof}), do: {:ok, preload(proof)}

  def preload(proof) do
    proof |> Repo.preload(build_preload())
  end
end
