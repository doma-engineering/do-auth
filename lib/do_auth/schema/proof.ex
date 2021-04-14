defmodule DoAuth.Proof do
  use DoAuth.DBUtils, into: __MODULE__
  alias DoAuth.Entity
  alias DoAuth.Credential
  alias DoAuth.Crypto

  schema "proofs" do
    belongs_to(:verification_method, Entity)
    field(:signature, :string)
    has_one(:credential, Credential)
    field(:timestamp, :utc_datetime)
  end

  @spec sign_map(map(), Crypto.keypair()) :: Crypto.detached_sig()
  def sign_map(xs, kp) do
    xs |> Jason.encode!() |> Crypto.sign(kp)
  end

  ## TODO: canonical JSON rep
  @spec changeset(ingredients()) :: Changeset.t()
  def changeset(stuff) do
    result = Ecto.build_assoc(stuff[:verification_method], :proofs)
    result |> change()
  end

  @spec to_map(%__MODULE__{}, [unwrapped: true] | []) :: map()
  def to_map(%__MODULE__{timestamp: timestamp, verification_method: entity, signature: sig},
        unwrapped: true
      ) do
    # TODO: Make use of proof_purposes table :shrug:
    %{
      type: "libsodium2021",
      created: timestamp,
      proofPurpose: "assertionMethod",
      verificationMethod: Entity.to_map(entity, unwrap: true),
      # TODO: test that sig can only be represented by URLsafe base 64.
      signature: sig
    }
  end

  def to_map(x, []), do: to_map(x)
  @spec to_map(%__MODULE__{}) :: map()
  def to_map(x = %__MODULE__{}), do: %{proof: to_map(x, unwrapped: true)}

  DBUtils.codegen(into: __MODULE__, no_changeset: true, canonical_from_map: true)
end
