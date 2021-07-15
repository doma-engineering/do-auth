defmodule DoAuth.Schema.Proof do
  @moduledoc """
  Funcitons required to take a proofless credential and make it verifiable.
  """
  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.Crypto

  schema "proofs" do
    belongs_to(:verification_method, Issuer)
    field(:signature, :string)
    has_one(:credential, Credential)
    field(:timestamp, :utc_datetime, read_after_writes: true)
  end

  @spec canonical_sign!(Crypto.canonicalised_value(), Crypto.keypair()) :: Crypto.detached_sig()
  def canonical_sign!(canonical_term, kp) do
    canonical_term |> Jason.encode!() |> Crypto.sign(kp)
  end

  @spec canonical_sign(Crypto.canonicalised_value(), Crypto.keypair()) ::
          {:ok, String.t()} | {:error, any()}
  def canonical_sign(canonical_term, kp) do
    try do
      true = Crypto.is_canonicalised?(canonical_term)
      {:ok, canonical_sign!(canonical_term, kp)}
    rescue
      e -> {:error, e}
    end
  end

  @spec canonical_sign64!(Crypto.canonicalised_value(), Crypto.keypair()) :: String.t()
  def canonical_sign64!(canonical_term, kp),
    do: canonical_sign!(canonical_term, kp)[:signature] |> Crypto.show()

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
end
