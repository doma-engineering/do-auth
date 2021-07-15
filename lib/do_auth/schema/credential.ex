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

  @spec build_by_subject_id(pos_integer()) :: Ecto.Query.t()
  def build_by_subject_id(x) do
    from(c in Credential, where: c.subject_id == ^x)
  end

  @spec one_by_subject_id(pos_integer()) :: %__MODULE__{}
  def one_by_subject_id(x) do
    build_by_subject_id(x) |> Repo.one()
  end

  @spec one_by_subject_id!(pos_integer()) :: %__MODULE__{}
  def one_by_subject_id!(x) do
    build_by_subject_id(x) |> Repo.one!()
  end

  @spec all_by_subject_id(pos_integer()) :: list(%__MODULE__{})
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
  @spec transact_with_keypair_from_subject_map(
          %{optional(:secret) => binary(), public: binary()},
          map(),
          map(),
          [{:signature64, String.t()} | {:timestamp, DateTime.t()} | {:preload, boolean()}]
        ) :: {:ok, %__MODULE__{}} | {:error, any()}
  def transact_with_keypair_from_subject_map(kp, claim, misc \\ %{}, opts \\ [])

  def transact_with_keypair_from_subject_map(
        %{public: pk} = kp,
        %{} = credential_subject,
        %{} = misc,
        [] = opts
      ) do
    try do
      case Repo.transaction(fn ->
             require Logger
             tau0 = with_opts_get_timestamp(opts)

             Logger.warn("Tick")
             did = DID.one_by_pk!(pk)
             Logger.warn("Tack")

             issuer = Issuer.sin_one_did!(did)
             Logger.warn("Quack")
             subject = Subject.sin_any_credential_subject!(credential_subject)
             Logger.warn("Duck")

             cred_so_far = %__MODULE__{
               contexts: [],
               types: [],
               issuer: issuer,
               timestamp: tau0,
               subject: subject,
               misc: misc
             }

             Logger.warn("Puck, #{inspect(cred_so_far, pretty: true)}")

             sig64 = with_keypair_and_opts_get_signature64(kp, opts, cred_so_far)
             Logger.warn("Guack")

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

  @spec transact_with_keypair_from_subject_map!(
          %{:public => binary(), optional(:secret) => binary()},
          map(),
          map(),
          list()
        ) :: %__MODULE__{}
  def transact_with_keypair_from_subject_map!(kp, claim, misc \\ %{}, opts \\ [])

  def transact_with_keypair_from_subject_map!(x, y, z, opts) do
    {:ok, res} = transact_with_keypair_from_subject_map(x, y, z, opts)
    res
  end

  @spec build_preload :: [
          :contexts | :subject | :types | [{:issuer, [...]} | {:proof, [...]}, ...],
          ...
        ]
  def build_preload() do
    [
      [issuer: [:url, did: [:issuer, :key]]],
      :contexts,
      [proof: [verification_method: :did]],
      :subject,
      :types
    ]
  end

  @spec preload(
          %__MODULE__{}
          | {:ok, %__MODULE__{}}
          | list(%__MODULE__{})
          | {:error, any()}
        ) ::
          %__MODULE__{}
          | {:ok, %__MODULE__{}}
          | list(%__MODULE__{})

  def preload({:error, e}), do: {:error, e}
  def preload({:ok, x}), do: {:ok, preload(x)}

  def preload(%__MODULE__{} = cred) do
    cred |> Repo.preload(build_preload())
  end

  @spec to_claim_map(%__MODULE__{}) :: map()
  def to_claim_map(
        %__MODULE__{
          contexts: ctxs,
          types: ts,
          issuer: issuer,
          subject: subject,
          timestamp: timestamp
        } = _cred
      ) do
    require Logger

    Logger.warn("Hoogak ")

    val = %{
      "@context" => ctxs,
      "type" => ts,
      "issuer" => Issuer.to_string(issuer),
      "issuanceDate" => timestamp,
      "credentialSubject" => Subject.to_map(subject)
    }

    Logger.warn("Doran, #{inspect(val)}")
    val
  end

  defp with_opts_get_timestamp(opts) do
    if Keyword.has_key?(opts, :timestamp) do
      opts[:timestamp]
    else
      DoAuth.Repo.now()
    end
  end

  defp with_keypair_and_opts_get_signature64(kp, opts, cred_so_far) do
    if Keyword.has_key?(opts, :signature) do
      opts[:signature]
    else
      cano =
        cred_so_far
        |> to_claim_map()
        |> Crypto.canonicalise_term!()

      require Logger

      Logger.warn("CCCCCCCCC #{inspect(cano)}")

      cano
      |> Proof.canonical_sign64!(kp)
    end
  end
end
