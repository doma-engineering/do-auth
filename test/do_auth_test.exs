defmodule DoAuthTest do
  use ExUnit.Case
  doctest DoAuth

  alias DoAuth.Crypto

  @pass_iolist ["tiny🏯", "grasshōpper👹"]
  @pass_binary "tiny🏯grasshōpper👹"

  test "has secret key base set" do
    assert(
      Application.get_env(:do_auth, DoAuth.Web)
      |> Keyword.fetch!(:secret_key_base) == "do-auth-test-key-base"
    )
  end

  test "can generate main (a.k.a. 'master') keys" do
    # Run this once
    {mkey_real, _} = Crypto.main_key_init(@pass_iolist)
    # TODO: Prop-test with weak crypto params
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

  @doc """
  Never run actual code with these cryptography params. Your hashes shall be
  extremely vulnerable to bruteforce if you do so.
  """
  @spec very_weak_params() :: Crypto.params()
  def very_weak_params() do
    %{ops: 1, mem: 1_000_00, salt_size: 16}
  end
end
