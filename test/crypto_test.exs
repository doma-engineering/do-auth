defmodule DoAuthCryptoTest do
  use DoAuth.Boilerplate.DatabaseStuff
  use DoAuth.DataCase

  alias DoAuth.Crypto
  alias DoAuth.Cat

  @pass_iolist ["tiny🏯", "grasshōpper👹"]
  @pass_binary "tiny🏯grasshōpper👹"

  @doc """
  Never run actual code with these cryptography params. Your hashes shall be
  extremely vulnerable to bruteforce if you do so.
  """
  @spec very_weak_params() :: Crypto.params()
  def very_weak_params() do
    %{ops: 1, mem: 100_000, salt_size: 16}
  end

  test "has secret key base set" do
    assert(
      Application.get_env(:do_auth, DoAuth.Web)
      |> Keyword.fetch!(:secret_key_base) ==
        "do auth test key base 123456789abcdefghijklmnopqrstuvwxyz tail 1"
    )
  end

  test "can generate main (a.k.a. 'master') keys" do
    # Run this once
    {mkey_real, _} = Crypto.main_key_init(@pass_iolist)
    {mkey, slip} = Crypto.main_key_init(@pass_iolist, very_weak_params())
    mkey1 = Crypto.main_key_reproduce(@pass_binary, slip)
    assert(mkey == mkey1)
    assert(mkey != mkey_real)
  end

  test "can create detached signatures from main key" do
    with {mkey, _} <- Crypto.main_key_init(@pass_iolist, very_weak_params()) do
      msg = ["hello", " ", "world"]
      keypair = Crypto.derive_signing_keypair(mkey, 1)
      detached_signature = Crypto.sign(msg, keypair)
      assert(Crypto.verify(msg, detached_signature))
    end
  end

  test "signatures are tripping" do
    with {mkey, _} <- Crypto.main_key_init(@pass_iolist, very_weak_params()) do
      msg = ["hello", " ", "world"]
      keypair = Crypto.derive_signing_keypair(mkey, 1)
      %{public: pk, signature: sig} = Crypto.sign(msg, keypair)

      assert(Crypto.verify(msg, %{public: pk, signature: sig |> Crypto.show() |> Crypto.read!()}))
    end
  end

  test "can derive server keypair" do
    %{public: p, secret: s} = Crypto.server_keypair()
    assert(p |> Crypto.show() == "xCCmJIknKGC_UxcQde0w2JCC_ADj8nrJZ2MK34aGVJM=")

    assert(
      s |> Crypto.show() ==
        "dKk5tDAtHXlml8BFGkNwh-BihH92kDPyHcl30VzHRj3EIKYkiScoYL9TFxB17TDYkIL8AOPyeslnYwrfhoZUkw=="
    )
  end

  test "can fmap show over enumerables" do
    f = &Crypto.show(&1)
    assert({:error, _} = Cat.fmap("hello", f))
    assert(["aGVsbG8="] == Cat.fmap!(["hello"], f))
    assert(%{"x" => {"embedded", "YXJpYQ=="}} == Cat.fmap!(%{"x" => {"embedded", "aria"}}, f))
    assert(%{atom: ["aGVsbG8=", "YXJpYQ=="]} == Cat.fmap!(%{atom: ["hello", "aria"]}, f))
  end
end
