defmodule DoAuth.Repo.Migrations.InitialSchema do
  use Ecto.Migration

  # Thanks @kernel and @pochen from elixir-lang.slack.com
  # for keeping me on track and doing what matters first.

  def change do

    # Many-to-many with 'credentials'
    create table(:contexts) do
      add :context, :string, null: false
      add :misc, :map
    end
    create unique_index(:contexts, [:context])

    # Many-to-many with 'credentials'
    create table(:_credential_types) do
      add :type, :string, null: false
      add :misc, :map
    end
    create unique_index(:_credential_types, [:type])

    create table(:keys) do
      add :publicKey, :string, null: false
      add :purpose, :string, null: false, default: "authentication"
      add :misc, :map
    end
    create unique_index(:keys, [:publicKey])

    # Table of DIDs registered with us
    create table(:dids) do
      add :method, :string, null: false, default: "doma"
      add :body, :string, null: false
      add :path, :map
      add :publicKey, references(:keys), null: false
      add :misc, :map
    end
    create unique_index(:dids, [:method, :body, :path])

    create table(:issuers) do
      add :url, :string, null: false
      add :misc, :map
    end
    create unique_index(:issuers, [:url])

    create table(:entities) do
      add :did, references(:dids)
      add :issuer, references(:issuers)
    end
    create constraint(:entities,
                      :did_xor_issuer,
                      check:
                        "(did IS NULL OR issuer IS NULL) AND (did IS NOT NULL OR issuer IS NOT NULL)")

    create table(:subjects) do
      add :claim, :map, null: false
      add :misc, :map
    end
    create unique_index(:subjects, [:claim])

    create table(:_proof_types) do
      add :type, :string, null: false
      add :misc, :map
    end
    create unique_index(:_proof_types, [:type])

    create table(:_proof_purposes) do
      add :purpose, :string, null: false
      add :misc, :map
    end
    create unique_index(:_proof_purposes, [:purpose])

    create table(:proofs) do
      # AKA "created"
      add :timestamp, :utc_datetime, default: fragment("NOW()"), null: false
      add :verificationMethod, references(:entities), null: false
      add :signature, :string, null: false
    end
    create unique_index(:proofs, [:signature])

    create table(:credentials) do
      add :issuer, references(:entities), null: false
      # AKA "issuanceDate" (talk about consistent naming in W3 standards lol)
      add :timestamp, :utc_datetime, default: fragment("NOW()"), null: false
      add :credentialSubject, references(:subjects)
      add :proof, references(:proofs)
      add :misc, :map
    end

    # This is the event log of adding stuff others shall be able to see through API
    # You can fold it to get the final disclosure configuration
    create table(:disclosures) do
      add :did, references(:dids)
      add :timestamp, :utc_datetime, default: fragment("NOW()")
      # Disclosure is a credential. It has a proof attached.
      # Disclosure configuration object is under :claim mapping of the :subjects table
      add :disclosure, references(:credentials)
    end

    create table(:credentials_contexts, primary_key: false) do
      add :credential, references(:credentials), primary_key: true
      add :context, references(:contexts), primary_key: true
    end

    create table(:credentials__credential_types, primary_key: false) do
      add :credential, references(:credentials), primary_key: true
      add :context, references(:_credential_types), primary_key: true
    end

  end
end
