defmodule DBTest do
  use DoAuth.RepoCase
  use DoAuth.DBUtils
  alias DoAuth.Crypto

  alias DoAuth.Issuer
  alias DoAuth.DID
  alias DoAuth.Proof
  alias DoAuth.Entity
  alias DoAuth.Subject
  alias DoAuth.Credential
  alias DoAuth.Key

  ############

  test "can validate xorred changesets" do
    ingredients_good = %{method: "ok"}
    ingredients_bad = %{method: "not", body: "as much"}

    c_good =
      %DoAuth.DID{}
      |> cast(ingredients_good, [:method, :body])
      |> DoAuth.DBUtils.validate_xor([:method, :body])

    c_bad =
      %DoAuth.DID{}
      |> cast(ingredients_bad, [:method, :body])
      |> DoAuth.DBUtils.validate_xor([:method, :body])

    assert(c_good.valid? && c_good.required == [:method] && c_good.changes == ingredients_good)

    assert(
      !c_bad.valid? && !is_nil(Keyword.fetch(c_bad.errors, :method)) &&
        !is_nil(Keyword.fetch(c_bad.errors, :body))
    )
  end

  ############

  test "credentials can be stored" do
    tau0 = DateTime.utc_now() |> DateTime.truncate(:second)
    # Start making issuer of credential, which is a DID-Entity
    kp = %{public: pk} = Crypto.server_keypair()
    {:ok, %{insert_did: did}} = DID.from_new_pk(pk |> Crypto.show(), %{}) |> Repo.transaction()
    {:ok, entity} = Entity.from_did(did) |> Repo.insert(returning: true)
    # End making issuer of credential, and store it in "entity"

    # Start making the core of a credential, AKA "subject". Here it's a map holding a KV "tested_by: DBTest"
    {:ok, subject} =
      %{claim: %{tested_by: __MODULE__}}
      |> Subject.changeset()
      |> Repo.insert(returning: true)

    # End making subject, and store it in "subject"

    # Build a canonical map, to prepare for proving. Prover module will take
    # care to turn it into a canonical JSON representation.
    preload_entity = [:issuer, [did: :key]]

    credmap =
      Credential.to_map(
        %Credential{
          issuer: entity |> Repo.preload(preload_entity),
          subject: subject,
          contexts: [],
          types: [],
          # We store UTC times for everything, but we do have support for TimeZones using `tzdata`
          timestamp: tau0
        },
        proofless: true
      )

    # End making canonical representation of the new credential, storing in "credmap"

    # Prove the credential by signing and making a proof
    sig = credmap |> Proof.sign_map(kp)

    # Let's check if Crypto.read!/show is tripping:
    assert(Crypto.read!(Crypto.show(sig.signature)) == sig.signature)

    {:ok, proof} =
      Proof.from_sig(entity |> Repo.preload(:did), sig.signature |> Crypto.show())
      |> Repo.insert()

    # End proving, storing the proof in "proof"

    # Transform proof-less credmap into a proven credmap and persist it
    {:ok, _} =
      %Credential{}
      |> change(%{
        issuer: entity,
        subject: subject,
        proof: proof,
        contexts: [],
        types: [],
        timestamp: tau0
      })
      |> Repo.insert(returning: true)

    # End persisting credmap, storing the inserted value in cred

    # Ensure that a credential is indeed stored
    cred =
      %Credential{} =
      Repo.one(Credential)
      |> Repo.preload([
        :contexts,
        :types,
        [issuer: preload_entity],
        [proof: [verification_method: preload_entity]],
        :subject
      ])

    # Test that credential is verifiable
    assert(Credential.verify(cred, pk))
  end

  ############

  test "DID has canonical representation" do
    %{public: pk} = Crypto.server_keypair()
    {:ok, %{insert_did: did}} = DID.from_new_pk(pk |> Crypto.show(), %{}) |> Repo.transaction()

    assert(
      DID.show(did |> Repo.preload(:key)) ==
        "did:doma:#{Crypto.bland_hash(pk |> Crypto.show())}"
    )
  end

  ############

  test "can create DIDs and Keys from public keys" do
    {mkey, slip} = Crypto.main_key_init("password123", DoAuthTest.very_weak_params())

    {:ok, %{insert_did: did}} =
      mkey
      |> Crypto.derive_signing_keypair(42)
      |> Map.fetch!(:public)
      |> Crypto.show()
      |> DoAuth.DID.from_new_pk(%{})
      |> Repo.transaction()

    pk =
      Crypto.main_key_reproduce("password123", slip)
      |> Crypto.derive_signing_keypair(42)
      |> Map.fetch!(:public)
      |> Crypto.show()

    assert(did.body == Crypto.bland_hash(pk))
  end

  ############

  test "can create DIDs from existing public keys" do
    pk =
      Crypto.main_key_init("password123", DoAuthTest.very_weak_params())
      |> elem(0)
      |> Crypto.derive_signing_keypair(42)
      |> Map.fetch!(:public)
      |> Crypto.show()

    {:ok, did} =
      Key.changeset(%{public_key: pk, purpose: "testing"})
      |> Repo.insert!(returning: true)
      |> DID.from_pk(%{})
      |> Repo.insert()

    assert(did.body == Crypto.bland_hash(pk))
  end

  ############

  test "can add Issuer" do
    url = "https://auth.doma.dev/issuer/1"

    assert(
      url ==
        Issuer.changeset(%{url: url})
        |> Repo.insert(returning: [:url])
        |> (fn x -> elem(x, 1).url end).()
    )
  end

  ############

  test "can create entity both as DID and Issuer, but not both" do
    {mkey, _slip} = Crypto.main_key_init("password123", DoAuthTest.very_weak_params())

    {:ok, %{insert_did: _}} =
      mkey
      |> Crypto.derive_signing_keypair(42)
      |> Map.fetch!(:public)
      |> Crypto.show()
      |> DoAuth.DID.from_new_pk(%{})
      |> Repo.transaction()

    # Casually testing select btw
    did = Repo.one!(DID)

    {:ok, issuer} =
      Issuer.changeset(%{url: "https://auth.doma.dev/issuer/1"}) |> Repo.insert(returning: true)

    {:error, _} = Entity.changeset(%{issuer: issuer, did: did}) |> Repo.insert()
    {:ok, _} = Entity.changeset(%{did: did}) |> Repo.insert()
    {:ok, _} = Entity.changeset(%{issuer: issuer}) |> Repo.insert()
  end

  ############

  test "Subject inserts" do
    {:ok, subj} =
      %{claim: %{file: "db_test.ex", result: "a triumph", note: "huge success"}, foo: :bar}
      |> Subject.changeset()
      |> Repo.insert()

    assert(subj.claim.note == "huge success")
    assert(!Map.get(subj.claim, :foo))
  end
end
