defmodule DoAuth.Schema.Proof do
  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.Crypto

  schema "proofs" do
    belongs_to(:verification_method, Issuer)
    field(:signature, :string)
    has_one(:credential, Credential)
    field(:timestamp, :utc_datetime, read_after_writes: true)
  end

  @spec canonical_sign(Crypto.canonicalised_value(), Crypto.keypair()) :: Crypto.detached_sig()
  def canonical_sign(canonical_term, kp) do
    canonical_term |> Jason.encode!() |> Crypto.sign(kp)
  end

  @spec canonical_sign64(Crypto.canonicalised_value(), Crypto.keypair()) :: String.t()
  def canonical_sign64(canonical_term, kp),
    do: canonical_sign(canonical_term, kp)[:signature] |> Crypto.show()

  @spec from_signature64(%Issuer{}, String.t()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def from_signature64(issuer, sig64) do
    build_from_signature64(issuer, sig64) |> Repo.insert()
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

  def changeset(proof_schema \\ %__MODULE__{}, third_party_data) do
    proof_schema
    |> cast(third_party_data, [:signature, :verification_method_id])
    |> validate_required([:signature, :verification_method_id])
  end
end
