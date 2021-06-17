defmodule DoAuth.Proof do
  use DoAuth.DBUtils, into: __MODULE__
  alias DoAuth.Entity
  alias DoAuth.Credential
  alias DoAuth.Crypto

  schema "proofs" do
    belongs_to(:verification_method, Entity)
    field(:signature, :string)
    has_one(:credential, Credential)
    field(:timestamp, :utc_datetime, read_after_writes: true)
  end

  def from_sig(proving_entity, sig) do
    changeset(%{signature: sig, verification_method: proving_entity})
  end

  @spec sign_map(Crypto.canonicalised_value(), Crypto.keypair()) :: Crypto.detached_sig()
  def sign_map(xs, kp) do
    xs |> Jason.encode!() |> Crypto.sign(kp)
  end

  ## TODO: canonical JSON rep
  @spec changeset(ingredients()) :: Changeset.t()
  def changeset(stuff) do
    #stuff = Map.put_new(stuff, :timestamp, DBUtils.now())
    result = Ecto.build_assoc(stuff[:verification_method], :proofs)
    # TODO: understand how this function works. The fuck is change for instance?!
    # TODO: write docs for this function
    result |> change(stuff)
  end

  @spec to_map(%__MODULE__{}, [unwrapped: true] | []) :: map()
  def to_map(_p = %__MODULE__{timestamp: timestamp, verification_method: entity, signature: sig},
        unwrapped: true
      ) do
    # TODO: Make use of proof_purposes table :shrug:
    %{
      type: "libsodium2021",
      created: timestamp,
      proofPurpose: "assertionMethod",
      verificationMethod: Entity.show(entity),
      # TODO: test that sig can only be represented by URLsafe base 64.
      signature: sig
    }
  end

  def to_map(x, []), do: to_map(x)
  @spec to_map(%__MODULE__{}) :: map()
  def to_map(x = %__MODULE__{}), do: %{proof: to_map(x, unwrapped: true)}

  # TODO: Make sure that this and credential have not only bridge from JS but also all the way from JS to PGSQL.
  # Something like `by_struct` that will be finding the corresponding PGSQL item.
  def from_map(%{
        created: tau0,
        # TODO: Implement proof purposes
        proofPurpose: _purpose,
        signature: sig,
        verificationMethod: verEntity
      }) do
    %__MODULE__{timestamp: tau0, verification_method: Entity.read(verEntity), signature: sig}
  end

  DBUtils.codegen(into: __MODULE__, no_changeset: true, canonical_from_map: true)
end
