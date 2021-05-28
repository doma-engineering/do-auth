defmodule DoAuth.Credential do
  @moduledoc """
  Credential.

  Canonical field orders:
  TODO: change elixir's "issuer" to a rightful "entity"

  "@context" /        contexts
  id /                -
  type /              types
  issuer /            issuer
  issuanceDate /      timestamp
  credentialSubject / subject
  proof /             proof
  """

  use DoAuth.DBUtils, into: __MODULE__
  alias DoAuth.DBUtils
  alias DoAuth.DID
  alias DoAuth.Entity
  alias DoAuth.Key
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
    field(:misc, :map)
  end

  def tx_import_tofu!(cred_map) do
    {:ok, cred} =
      Repo.transaction(fn ->
        pk64 = cred_map.credentialSubject.me

        pk_stored =
          case pk64 |> Key.by_pk() |> Repo.all() do
            [] ->
              Key.changeset(%{public_key: pk64}) |> Repo.insert!()

            [x = %DoAuth.Key{}] ->
              x
          end

        did_stored =
          case DoAuth.DID.by_pk64(pk64) |> Repo.all() do
            [] ->
              DoAuth.DID.from_key(pk_stored) |> Repo.insert!()

            [x = %DoAuth.DID{}] ->
              x
          end

        _entity_stored =
          case DoAuth.Entity.by_did_id(did_stored.id) |> Repo.all() do
            [] ->
              DoAuth.Entity.from_did(did_stored) |> Repo.insert!()

            [x = %DoAuth.Entity{}] ->
              x
          end

        {:ok, tau0, 0} = cred_map.issuanceDate |> DateTime.from_iso8601()

        credential =
          case from(c in DoAuth.Subject,
                 where: fragment(~s(? ->> 'me' = ?), c.claim, ^pk64)
               )
               |> Repo.all() do
            [] ->
              tx_from_keypair_credential!(
                %{
                  public: Crypto.read!(pk64),
                  signature: cred_map.proof.signature |> Crypto.read!(),
                  timestamp: tau0
                },
                %{me: pk64}
              )

            [x = %DoAuth.Subject{}] ->
              from(c in DoAuth.Credential, where: c.subject_id == ^x.id) |> Repo.one!()
          end

        credential |> Repo.preload(preload_credential())
      end)

    cred
  end

  def preload_entity(), do: [:issuer, [did: :key]]

  def preload_credential(),
    do: [
      [issuer: [did: [:entity, :key]]],
      :contexts,
      [proof: [verification_method: :did]],
      :subject,
      :types
    ]

  @spec by_subject(%Subject{}) :: %__MODULE__{}
  @doc """
  Get credential by subject.
  """
  def by_subject(subj) do
    from(c in __MODULE__, where: c.subject_id == ^subj.id)
    |> Repo.one()
    |> Repo.preload(preload_credential())
  end

  @doc """
  Makes a credential from a keypair serialisable map (claim).
  """
  @spec tx_from_keypair_credential!(
          %{
            :public => binary(),
            optional(:secret) => binary(),
            optional(:signature) => binary(),
            # TODO: Recap how timestamps work in Elixir
            optional(:timestamp) => any(),
            optional(:misc) => map()
          },
          map()
        ) ::
          %__MODULE__{}
  def tx_from_keypair_credential!(x, y, z \\ %{})

  def tx_from_keypair_credential!(kp = %{public: pk}, claim, misc) do
    # require Logger
    # Logger.warn()

    {:ok, {:ok, cred}} =
      Repo.transaction(fn ->
        tau0 =
          unless Map.get(kp, :timestamp, false) do
            DBUtils.now()
          else
            kp.timestamp
          end

        did = DID.by_pk64(pk |> Crypto.show()) |> Repo.one()
        entity = Entity.by_did_id(did.id) |> Repo.one() |> Repo.preload(preload_entity())
        {:ok, subject} = %{claim: claim} |> Subject.changeset() |> Repo.insert(returning: true)

        # TODO: Make it clear that ID is not known at this stage and isn't
        # verified, which opens up an option for phishing and for shitty
        # implementations that are tricked by an unverified ID in a verified
        # credential to fetch a bogus one and treat it as correct.
        #
        # TODO: Make it also clear that misc.id will be used instead of auto
        # derived ID if provided
        proofless = %__MODULE__{
          contexts: [],
          types: [],
          issuer: entity,
          timestamp: tau0,
          subject: subject,
          misc: misc
        }

        sig =
          unless Map.get(kp, :signature, false) do
            proofless
            |> to_map(proofless: true)
            |> Crypto.canonicalise_term()
            |> Proof.sign_map(kp)
          else
            %{signature: kp.signature}
          end

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
    cred1 = cred |> to_map(proofless: true)
    cred1 |> Crypto.canonicalise_term() |> Jason.encode!()
  end

  @doc """
  Verifies a proof of Jason.encode!'ed proofless part of a credential.
  """
  @spec verify(%__MODULE__{}, binary()) :: boolean()
  def verify(cred = %__MODULE__{proof: %Proof{signature: sig}}, pk) do
    proofless = proofless_json(cred)
    Crypto.verify(proofless, %{public: pk, signature: sig |> Crypto.read!()})
  end

  @doc """
  Verifies a proof of Jason.encode!'ed proofless part of a credential, given an URLSAFE BASE64 ENCODED public key.
  """
  @spec verify64(%__MODULE__{}, binary()) :: boolean()
  def verify64(cred, pk64) do
    verify(cred, pk64 |> Crypto.read!())
  end

  @doc """
  Make a %Credential{} with canonical order of fields.
  """
  def from_map(
        _cred = %{
          "@context": ctx,
          credentialSubject: subj,
          issuanceDate: tau0,
          issuer: issuer,
          proof: proof,
          type: type
        }
      ) do
    # [x] This complies with the canonical field orders
    %__MODULE__{
      contexts: ctx,
      types: type,
      issuer: Entity.read(issuer),
      timestamp: tau0,
      subject: subj,
      proof: Proof.from_map(proof)
    }
  end

  @spec to_map(%__MODULE__{}, [unwrapped: true] | [proofless: true] | []) :: map()
  def to_map(cred = %__MODULE__{proof: proof}, unwrapped: true) do
    to_map(cred, proofless: true)
    |> Map.put_new(:proof, Proof.to_map(proof, unwrapped: true))
    |> Map.put_new(:id, mk_cred_id(cred))
  end

  def to_map(
        _cred = %__MODULE__{
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

  @doc """
  We have decided against using full URLs for credentials like shown in VC data
  model standard. Not the last reason is that in some high availability
  settings, replicant servers may be accessible through fqdn fallback and not be
  behind the same load balancer.

  Normally, IDs of credentials are just salted hashes of proofless JSON versions
  of credentials. This is done to achieve addressibility without predictability
  of hashes. Indeed, if we would use bland (unsalted) hashes, Malice who forgot
  her friend's Alice's birth date, would be able to, knowing Alice's DID and the
  time when she got her registration, enumerate proofless JSONs, eventually
  finding the information.
  """
  @spec mk_cred_id(%__MODULE__{}) :: String.t()
  def mk_cred_id(x, y \\ [])

  def mk_cred_id(cred = %__MODULE__{}, cloaked: false),
    do:
      Map.get(
        cred.misc,
        "location",
        "/credentials/#{Crypto.salted_hash(cred |> :erlang.term_to_binary())}"
      )

  def mk_cred_id(cred = %__MODULE__{}, _),
    do: Map.get(cred.misc, "location", "/credential/cloaked")

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
      # TODO: This is something really shady and really deep. We probably should
      # do something about this mess.
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
