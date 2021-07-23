defmodule DoAuth.Schema.Credential do
  @moduledoc """
  Credential. You guessed.
  """

  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.{Crypto, Cat}

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
        opts
      )
      when is_list(opts) do
    try do
      Repo.transaction(fn ->
        tau0 = with_opts_get_timestamp(opts)

        did = DID.one_by_pk!(pk)

        issuer = Issuer.sin_one_did!(did)
        subject = Subject.sin_any_credential_subject!(credential_subject)

        cred_so_far =
          to_claim_map(
            %__MODULE__{
              contexts: [],
              types: [],
              issuer: issuer,
              timestamp: tau0,
              subject: subject,
              misc: misc
            },
            opts
          )

        sig64 = mk_signature_with_opts(kp, cred_so_far, opts) |> Crypto.show()

        {:ok, cred} =
          %__MODULE__{
            contexts: Map.get(cred_so_far, "@context"),
            types: Map.get(cred_so_far, "type"),
            issuer: issuer,
            timestamp: tau0,
            subject: subject,
            misc: misc,
            proof: Proof.from_signature64!(issuer, sig64)
          }
          |> Repo.insert(returning: true)

        cred |> preload()
      end)
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
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

  def preload(cred) when is_list(cred) do
    cred |> Repo.preload(build_preload())
  end

  @spec to_map(%DoAuth.Schema.Credential{}) :: map
  def to_map(
        %__MODULE__{
          contexts: ctxs,
          types: ts,
          issuer: issuer,
          subject: subject,
          timestamp: timestamp,
          misc: misc
        } = cred
      ) do
    p = &Cat.put_new_value(&1, &2, &3)
    g = &Map.get(cred, &1)
    m = &Map.get(misc, &1)
    pm = &Cat.put_new_value(&1, &2, Map.get(misc, &2))

    %{
      "@context" => ctxs,
      "type" => ts,
      "issuer" => Issuer.to_string(issuer),
      "issuanceDate" => DateTime.to_iso8601(timestamp),
      "credentialSubject" => Subject.to_map(subject)
    }
    |> p.("id", m.("location"))
    |> pm.("effectiveDate")
    |> pm.("validFrom")
    |> pm.("validUntil")
    |> Cat.put_new_association("proof", g.(:proof), &Proof.to_map(&1))
  end

  @spec to_claim_map(map() | %__MODULE__{}, list()) :: map()
  def to_claim_map(cred, _opts \\ []) do
    to_map(cred) |> Map.delete("id") |> Map.delete("proof")
  end

  defp with_opts_get_timestamp(opts) do
    if Keyword.has_key?(opts, :timestamp) do
      opts[:timestamp]
    else
      DoAuth.Repo.now()
    end
  end

  defp mk_signature_with_opts(kp, cred_so_far, opts) do
    if Keyword.has_key?(opts, :signature) do
      opts[:signature]
    else
      canonical =
        cred_so_far
        |> Crypto.canonicalise_term!()

      canonical
      |> Proof.canonical_sign!(kp)
      |> Map.get(:signature)
    end
  end
end
