defmodule DoAuthCryptoTest do
  @moduledoc """
  Testing DoAuth crypto suite.
  """
  use DoAuth.Boilerplate.DatabaseStuff
  use DoAuth.DataCase
  use DoAuth.Test.Support.Fixtures, [:crypto]

  alias DoAuth.Crypto
  alias DoAuth.Cat

  @pass_iolist ["hello🏯", "wōrld👹"]
  @pass_binary "hello🏯wōrld👹"

  @doc """
  Never run actual code with these cryptography params. Your hashes shall be
  extremely vulnerable to bruteforce if you do so.
  """
  @spec very_weak_params() :: Crypto.params()
  def very_weak_params() do
    %{ops: 1, mem: 100_000, salt_size: 16}
  end

  test "fixtures are in line with this suite" do
    assert(very_weak_params() == very_weak_params_fixture())
    assert(@pass_binary == password_fixture())
  end

  test "has secret key base set" do
    assert(
      Application.get_env(:do_auth, DoAuth.Web)
      |> Keyword.fetch!(:secret_key_base) ==
        "do auth test key base 123456789abcdefghijklmnopqrstuvwxyz tail 1"
    )
  end

  test "can generate main keys" do
    # Run this once
    {mkey_real, _} = Crypto.main_key_init(@pass_iolist)
    {mkey, slip} = Crypto.main_key_init(@pass_iolist, very_weak_params())
    mkey1 = Crypto.main_key_reproduce(@pass_binary, slip)
    assert(mkey == mkey1)
    assert(mkey != mkey_real)
  end

  test "main keys are reproduced the same way as they are in fixtures" do
    mkey = Crypto.main_key_reproduce(@pass_binary, slip_fixture())
    {mkey1, _} = main_key_fixture()
    assert(mkey == mkey1)
  end

  test "can create iolist-compatible detached signatures from main key" do
    msg = ["hello", " ", "world"]
    keypair = signing_key_id_1_fixture()
    detached_signature = Crypto.sign(msg, keypair)
    assert(Crypto.verify(msg, detached_signature))
    assert(Crypto.verify(Enum.join(msg), detached_signature))
  end

  test "signatures are tripping" do
    msg = ["hello", " ", "world"]
    keypair = signing_key_id_1_fixture()
    %{public: pk, signature: sig} = Crypto.sign(msg, keypair)
    assert(Crypto.verify(msg, %{public: pk, signature: sig |> Crypto.show() |> Crypto.read!()}))
  end

  test "sign_map is verifiable" do
    naive_claim = %{"pola" => "cutie", "timestamp" => DoAuth.Repo.now()}
    keypair = signing_key_id_1_fixture()
    verifiable_naive_claim = Crypto.sign_map!(keypair, naive_claim, if_did_missing: :insert)
    assert(Crypto.verify_map(verifiable_naive_claim))

    assert(
      DoAuth.Schema.Proof.canonical_verify64!(
        naive_claim |> Crypto.canonicalise_term!(),
        %{
          signature: verifiable_naive_claim["proof"]["signature"],
          public: keypair[:public] |> Crypto.show()
        }
      )
    )
  end

  test "server keypair is stable" do
    %{public: p, secret: s} = Crypto.server_keypair()
    assert(p |> Crypto.show() == "xCCmJIknKGC_UxcQde0w2JCC_ADj8nrJZ2MK34aGVJM=")

    assert(
      s |> Crypto.show() ==
        "dKk5tDAtHXlml8BFGkNwh-BihH92kDPyHcl30VzHRj3EIKYkiScoYL9TFxB17TDYkIL8AOPyeslnYwrfhoZUkw=="
    )
  end

  test "can create and verify embedded proofs" do
  end

  test "fmap show over enumerables" do
    f = &Crypto.show(&1)
    assert({:error, _} = Cat.fmap("hello", f))
    assert(["aGVsbG8="] == Cat.fmap!(["hello"], f))
    assert(%{"x" => {"embedded", "YXJpYQ=="}} == Cat.fmap!(%{"x" => {"embedded", "aria"}}, f))
    assert(%{atom: ["aGVsbG8=", "YXJpYQ=="]} == Cat.fmap!(%{atom: ["hello", "aria"]}, f))
  end
end
