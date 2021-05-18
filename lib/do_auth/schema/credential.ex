defmodule DoAuth.Credential do
  use DoAuth.DBUtils, into: __MODULE__
  alias DoAuth.DBUtils
  alias DoAuth.DID
  alias DoAuth.Entity
  alias DoAuth.Subject
  alias DoAuth.Proof
  alias DoAuth.Context
  alias DoAuth.Crypto
  alias DoAuth.CredentialContext, as: CC
  alias DoAuth.CredentialType
  alias DoAuth.CredentialCredentialType, as: CCT
  # alias Ecto.Multi

  schema "credentials" do
    belongs_to(:issuer, Entity)
    belongs_to(:subject, Subject)
    belongs_to(:proof, Proof)
    many_to_many(:contexts, Context, join_through: CC)
    many_to_many(:types, CredentialType, join_through: CCT)
    field(:timestamp, :utc_datetime)
  end

  @spec preload_entity :: [:issuer | [{:did, :key}, ...], ...]
  def preload_entity(), do: [:issuer, [did: :key]]

  @doc """
  Makes a credential from a keypair serialisable map (claim).
  """
  @spec tx_from_keypair_credential!(%{:public => binary(), :secret => binary()}, map()) ::
          %__MODULE__{}
  def tx_from_keypair_credential!(kp = %{public: pk}, claim) do
    {:ok, {:ok, cred}} =
      Repo.transaction(fn ->
        tau0 = DBUtils.now()
        did = DID.by_pk64(pk |> Crypto.show()) |> Repo.one()
        entity = Entity.by_did_id(did.id) |> Repo.one() |> Repo.preload(preload_entity())
        {:ok, subject} = %{claim: claim} |> Subject.changeset() |> Repo.insert(returning: true)

        proofless = %__MODULE__{
          timestamp: tau0,
          issuer: entity,
          subject: subject,
          contexts: [],
          types: []
        }

        sig = proofless |> to_map(proofless: true) |> Proof.sign_map(kp)
        {:ok, proof} = Proof.from_sig(entity, sig.signature |> Crypto.show()) |> Repo.insert()
        %{proofless | proof: proof} |> Repo.insert(returning: true)
      end)

    cred
  end

  @doc """
  The part of credential used to create a proof.
  """
  @spec proofless_json(%__MODULE__{}) :: String.t()
  def proofless_json(cred = %__MODULE__{}) do
    cred |> to_map(proofless: true) |> Jason.encode!()
  end

  # defp dbg(x), do: inspect(x, pretty: true)

  @doc """
  Verifies a proof of Jason.encode!'ed proofless part of a credential.
  """
  @spec verify(%__MODULE__{}, binary()) :: boolean()
  def verify(cred = %__MODULE__{proof: %Proof{signature: sig}}, pk) do
    proofless = proofless_json(cred)
    Crypto.verify(proofless, %{public: pk, signature: sig |> Crypto.read!()})
  end

  @spec to_map(%__MODULE__{}, [unwrapped: true] | [proofless: true] | []) :: map()
  def to_map(cred = %__MODULE__{proof: proof}, unwrapped: true) do
    to_map(cred, proofless: true)
    |> Map.put_new(:proof, Proof.to_map(proof, unwrapped: true))
    |> Map.put_new(:id, to_url(cred))
  end

  def to_map(
        %__MODULE__{
          contexts: ctxs,
          types: ts,
          issuer: entity,
          subject: subject,
          timestamp: timestamp
        },
        proofless: true
      ) do
    %{
      "@context": ctxs,
      type: ts,
      issuer: Entity.show(entity),
      issuanceDate: timestamp,
      credentialSubject: Subject.to_map(subject, unwrapped: true)
    }
  end

  # TODO: DEFINE FUNCTORIAL TOJSON???

  def to_map(x, []), do: to_map(x)

  @spec to_map(%__MODULE__{}) :: map()
  def to_map(x = %__MODULE__{}), do: %{credential: to_map(x, unwrapped: true)}

  @spec to_url(%__MODULE__{}) :: String.t()
  def to_url(cred = %__MODULE__{}),
    do: "unavailable/credentials/#{Crypto.salted_hash(cred |> :erlang.term_to_binary())}"

  # TODO: test
  @spec insert(%Entity{}, %Subject{}, %Proof{}, list(%Context{}), list(%CredentialType{})) ::
          {:ok | :error, any()}
  def insert(issuer = %Entity{}, subject = %Subject{}, proof = %Proof{}, ctxs, types) do
    changeset(%__MODULE__{}, %{issuer: issuer, subject: subject, proof: proof})
    |> Repo.insert(returning: [:id])
    |> maybe_tag_credential_with_contexts_and_types(ctxs, types)
  end

  # TODO: Unify, put into a lib.
  defp maybe_tag_credential_with_contexts_and_types(err = {:error, _}, _ctxs, _types), do: err

  defp maybe_tag_credential_with_contexts_and_types({:ok, cred}, ctxs, types) do
    # Prevent hadouken https://i.imgur.com/BtjZedW.jpg !
    [
      tag_all(cred, ctxs, &CC.changeset(%{credential: &1, context: &2})),
      tag_all(cred, types, &CCT.changeset(%{credential: &1, type: &2}))
    ]
    |> Enum.reduce_while(:start, fn f, _acc -> f.() end)
  end

  defp tag_all(cred, ctxs, mk_changeset) do
    fn ->
      ctxs
      |> Enum.reduce_while(:start, &tag_once(cred, mk_changeset).(&1, &2))
      |> to_cont()
    end
  end

  defp tag_once(cred, mk_changeset) do
    fn tag, _acc ->
      mk_changeset.(cred, tag)
      |> Repo.insert()
      |> to_cont()
    end
  end

  defp to_cont(ok = {:ok, _}), do: {:cont, ok}
  defp to_cont(err = {:error, _}), do: {:halt, err}

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    with required <- [:issuer, :subject, :proof] do
      c |> cast(stuff, [:contexts, :types] ++ required) |> validate_required(required)
    end
  end

  DBUtils.codegen(into: __MODULE__)
end
