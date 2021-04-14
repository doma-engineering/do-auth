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
    create table(:credential_types) do
      add :type, :string, null: false
      add :misc, :map
    end
    create unique_index(:credential_types, [:type])

    create table(:keys) do
      add :public_key, :string, null: false
      add :purpose, :string, null: false, default: "authentication"
      add :misc, :map
    end
    create unique_index(:keys, [:public_key])

    # Table of DIDs registered with us
    create table(:dids) do
      add :method, :string, null: false, default: "doma"
      add :body, :string, null: false
      add :path, :map
      add :key_id, references(:keys), null: false
      add :misc, :map
    end
    create unique_index(:dids, [:method, :body, :path])

    create table(:issuers) do
      add :url, :string, null: false
      add :misc, :map
    end
    create unique_index(:issuers, [:url])

    create table(:entities) do
      add :did_id, references(:dids)
      add :issuer_id, references(:issuers)
    end
    create constraint(:entities,
                      :did_xor_issuer,
                      check:
                        "(did_id IS NULL OR issuer_id IS NULL) AND (did_id IS NOT NULL OR issuer_id IS NOT NULL)")

    create table(:subjects) do
      add :claim, :map, null: false
      add :misc, :map
    end
    create unique_index(:subjects, [:claim])

    create table(:proof_types) do
      add :type, :string, null: false
      add :misc, :map
    end
    create unique_index(:proof_types, [:type])

    create table(:proof_purposes) do
      add :purpose, :string, null: false
      add :misc, :map
    end
    create unique_index(:proof_purposes, [:purpose])

    create table(:proofs) do
      # AKA "created"
      add :timestamp, :utc_datetime, default: fragment("NOW()"), null: false
      add :verification_method_id, references(:entities), null: false
      add :signature, :string, null: false
    end
    create unique_index(:proofs, [:signature])

    create table(:credentials) do
      add :issuer_id, references(:entities), null: false
      # AKA "issuanceDate" (talk about consistent naming in W3 standards lol)
      add :timestamp, :utc_datetime, default: fragment("NOW()"), null: false
      add :subject_id, references(:subjects)
      add :proof_id, references(:proofs)
      add :misc, :map
    end

    # This is the event log of adding stuff others shall be able to see through API
    # You can fold it to get the final disclosure configuration
    create table(:disclosures) do
      add :did_id, references(:dids)
      add :timestamp, :utc_datetime, default: fragment("NOW()")
      # Disclosure is a credential. It has a proof attached.
      # Disclosure configuration object is under :claim mapping of the :subjects table
      add :disclosure_id, references(:credentials)
    end

    create table(:credentials_contexts, primary_key: false) do
      add :credential_id, references(:credentials), primary_key: true
      add :context_id, references(:contexts), primary_key: true
    end

    create table(:credentials_credential_types, primary_key: false) do
      add :credential_id, references(:credentials), primary_key: true
      add :context_id, references(:credential_types), primary_key: true
    end

  end
end
