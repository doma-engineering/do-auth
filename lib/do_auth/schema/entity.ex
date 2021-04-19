defmodule DoAuth.Entity do
  @moduledoc """
  Entity is either an Issuer or a DID.
  """
  use DoAuth.DBUtils, into: __MODULE__

  schema "entities" do
    belongs_to(:did, DoAuth.DID)
    belongs_to(:issuer, DoAuth.Issuer)
    has_many(:proofs, DoAuth.Proof, foreign_key: :verification_method_id)
  end

  def show(%__MODULE__{issuer_id: nil, did: did = %DoAuth.DID{}}) do
    did |> Repo.preload(:key) |> DoAuth.DID.show()
  end

  def show(%__MODULE__{did_id: nil, issuer: issuer = %DoAuth.Issuer{}}) do
    issuer |> DoAuth.Issuer.show()
  end

  def to_map(%__MODULE__{issuer_id: nil, did: did = %DoAuth.DID{}}, opts) do
    did |> Repo.preload(:key) |> DoAuth.DID.to_map(opts)
  end

  def to_map(%__MODULE__{did_id: nil, issuer: issuer = %DoAuth.Issuer{}}, opts) do
    issuer |> DoAuth.Issuer.to_map(opts)
  end

  def to_map(x), do: to_map(x, [])

  def from_did(did), do: changeset(%{did: did})
  def from_issuer(issuer), do: changeset(%{issuer: issuer})

  @doc """
  Sadly, it seems like `changeset`s aren't compatible with this use-case,
  i.e. there is no function that would simply cast a preloaded instance of a
  schema and associate it with a single new instance of another schema
  (perhaps persisting it).

  Simply put, there is no way something like this can work with changesets:

  ```
  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    with xs <- [:issuer, :did] do
      c |> cast(stuff, xs) |> DBUtils.validate_xor(xs)
    end
  end
  ```

  even if you strip away everything but "id" with an expression such as this:

  ```
  stuff = stuff |> Enum.map(fn {k, v} -> {k, v.id} end) |> Enum.into(%{})
  ```

  Thus, we do not expose a standard changeset option in this module, but
  instead we are going for a function that validates and persists straight
  away, abusing Schema-less changesets!
  """
  @spec changeset(nil | keyword | map) :: Ecto.Changeset.t()
  def changeset(stuff) do
    with result <-
           (if stuff[:did] do
              Ecto.build_assoc(stuff[:did], :entity)
            else
              Ecto.build_assoc(stuff[:issuer], :entity)
            end) do
      dummy_schema = %{did: :integer, issuer: :integer}
      ids = stuff |> Enum.map(fn {k, v} -> {k, Map.get(v, :id)} end) |> Enum.into(%{})

      dummy_changeset =
        {%{}, dummy_schema}
        |> cast(ids, Map.keys(dummy_schema))
        |> DBUtils.validate_xor(Map.keys(dummy_schema))

      if dummy_changeset.valid? do
        result |> change()
      else
        dummy_changeset
      end
    end
  end

  DBUtils.codegen(into: __MODULE__, no_changeset: true, canonical_from_map: true)
end
