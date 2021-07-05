defmodule DoAuth.Schema.Credential do
  @moduledoc """
  Credential. You guessed.
  """

  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.{Crypto}

  schema "credentials" do
    belongs_to(:issuer, Issuer)
    belongs_to(:subject, Subject)
    belongs_to(:proof, Proof)
    many_to_many(:contexts, Context, join_through: CredentialContext)
    many_to_many(:types, CredentialType, join_through: CredentialCredentialType)
    field(:timestamp, :utc_datetime, read_after_writes: true)
    field(:misc, :map)
  end

  def build_by_subject_id(x) do
    from(c in Credential, where: c.subject_id == ^x)
  end

  def one_by_subject_id!(x) do
    build_by_subject_id(x) |> Repo.one!()
  end

  def all_by_subject_id(x) do
    build_by_subject_id(x) |> Repo.all()
  end

  @doc """
  Give it keypair, a map with some subject, perhaps misc-metadata to be persisted and perhaps some options from

   - :signature64 -- ommit :secret in keypair and use this Base64 URL-safe signature instead;
   - :timestamp -- do not read current time with DoAuth.Repo.now and use this timestamp instead;
   - :preload -- is true by default, but if false, it won't preload fields, relevant to a credential after insertion;

  and, under transaction, a claim, that constitutes of

   - issuer (DID corresponding to public key given);
   - timestamp;
   - subject;

  shall be signed, yielding a proof.
  After which, both subject and proof shall be unified into a credential and inserted into the database.
  """
  def transact_with_keypair_from_subject_map(kp, claim, misc \\ %{}, opts \\ [])

  def transact_with_keypair_from_subject_map(
        %{public: pk} = kp,
        %{} = credential_subject,
        %{} = misc,
        [] = opts
      ) do
    try do
      case Repo.transaction(fn ->
             tau0 =
               unless Keyword.has_key?(opts, :timestamp) do
                 DoAuth.Repo.now()
               else
                 opts[:timestamp]
               end

             did = DID.one_by_pk!(pk)

             issuer =
               case Issuer.all_by_did_id(did.id) do
                 [%Issuer{} = e] -> e
                 [] -> Issuer.from_did_schema!(did)
                 _ -> impossible()
               end

             require Logger
             Logger.warn("Bug will happen now")

             subject =
               case Subject.all_by_credential_subject(credential_subject) do
                 [%Subject{} = s | _] -> s
                 [] -> Subject.from_credential_subject!(credential_subject)
                 _ -> impossible()
               end

             cred_so_far = %__MODULE__{
               contexts: [],
               types: [],
               issuer: issuer,
               timestamp: tau0,
               subject: subject,
               misc: misc
             }

             sig64 =
               unless Keyword.has_key?(opts, :signature) do
                 cred_so_far
                 |> to_claim_map()
                 |> Crypto.canonicalise_term()
                 |> Proof.canonical_sign64(kp)
               else
                 opts[:signature]
               end

             {:ok, cred} =
               %{cred_so_far | proof: Proof.from_signature64!(issuer, sig64)}
               |> Repo.insert(returning: true)

             cred
           end) do
        {:ok, cred} -> {:ok, cred |> preload()}
        err -> err
      end
    rescue
      e -> {:error, e}
    end
  end

  def transact_with_keypair_from_subject_map!(kp, claim, misc \\ %{}, opts \\ [])

  def transact_with_keypair_from_subject_map!(x, y, z, opts) do
    {:ok, res} = transact_with_keypair_from_subject_map(x, y, z, opts)
    res
  end

  def build_preload() do
    [
      [issuer: [:url, did: [:issuer, :key]]],
      :contexts,
      [proof: [verification_method: :did]],
      :subject,
      :types
    ]
  end

  # TODO: Make preloads not fail on {:error, x}
  def preload(%__MODULE__{} = cred) do
    cred |> Repo.preload(build_preload())
  end

  def to_claim_map(
        _cred = %__MODULE__{
          contexts: ctxs,
          types: ts,
          issuer: issuer,
          subject: subject,
          timestamp: timestamp
        }
      ) do
    %{
      "@context" => ctxs,
      "type" => ts,
      "issuer" => Issuer.to_string(issuer),
      "issuanceDate" => timestamp,
      "credentialSubject" => Subject.to_map(subject)
    }
  end

  defp impossible(), do: throw("impossible")
end
