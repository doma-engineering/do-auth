defmodule DBTest do
  use DoAuth.RepoCase
  use DoAuth.DBUtils
  alias DoAuth.Crypto

  alias DoAuth.URL
  alias DoAuth.DID
  # alias DoAuth.Proof
  alias DoAuth.Entity
  alias DoAuth.Subject
  alias DoAuth.Credential
  alias DoAuth.Key

  ############

  test "can validate xorred changesets" do
    _dids = Repo.all(DID)
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

  test "Credential.tx_from_keypair_credential! inserts credentials" do
    Repo.transaction(fn ->
      kp = %{public: pk} = Crypto.server_keypair()
      # Make sure that stuff's there
      did = sin_did(pk)
      {:ok, _entity} = Entity.from_did(did) |> Repo.insert(returning: true)

      cred = Credential.tx_from_keypair_credential!(kp, %{powo: "my love forever"})

      assert(Credential.verify(cred, pk))
    end)
  end

  ############

  test "credentials can be stored" do
    # This is already tested by the "populate" task that fires when we start the
    # system.
    assert(true)
  end

  test "Mission-critical TOFU data is populated" do
    %{public: pk} = Crypto.server_keypair()
    pk64 = pk |> Crypto.show()
    DoAuth.Persistence.populate_do()
    cred = Subject.by_claim_me(pk64) |> Credential.by_subject()
    assert(Credential.verify(cred, pk))
  end

  ############

  test "DID has canonical representation" do
    %{public: pk} = Crypto.server_keypair()

    did = sin_did(pk)

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
      |> DoAuth.DID.from_new_pk64(%{})
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
      |> DID.from_key(%{})
      |> Repo.insert()

    assert(did.body == Crypto.bland_hash(pk))
  end

  ############

  test "can add URL" do
    url = "https://auth.doma.dev/issuer/1"

    assert(
      url ==
        URL.changeset(%{url: url})
        |> Repo.insert(returning: [:url])
        |> (fn x -> elem(x, 1).url end).()
    )
  end

  ############

  test "can create entity both as DID and URL, but not both" do
    {mkey, _slip} = Crypto.main_key_init("password123", DoAuthTest.very_weak_params())

    dids0 = Repo.all(DID)

    {:ok, %{insert_did: _}} =
      mkey
      |> Crypto.derive_signing_keypair(42)
      |> Map.fetch!(:public)
      |> Crypto.show()
      |> DoAuth.DID.from_new_pk64(%{})
      |> Repo.transaction()

    # Casually testing select btw
    [did] = Repo.all(DID) -- dids0

    {:ok, url} =
      URL.changeset(%{url: "https://auth.doma.dev/issuer/1"}) |> Repo.insert(returning: true)

    {:error, _} = Entity.changeset(%{url: url, did: did}) |> Repo.insert()
    {:ok, _} = Entity.changeset(%{did: did}) |> Repo.insert()
    {:ok, _} = Entity.changeset(%{url: url}) |> Repo.insert()
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

  defp sin_did(pk) do
    case DID.by_pk64(pk |> Crypto.show()) |> Repo.all() do
      [x] ->
        x

      _ ->
        {:ok, %{insert_did: x}} =
          DID.from_new_pk64(pk |> Crypto.show(), %{}) |> Repo.transaction()

        x
    end
  end
end
