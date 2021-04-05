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

  test "can encode and decode URLs, URNs and DIDs" do
    protocol = "https"
    scheme = "did"
    fqdn = "test.aaa.doma.dev"
    port = 8443
    nil_port = nil

    method = "doma"
    did_id = "e7c7ec7d56197de97f9a73ae20d9672e99aebd48922a3d4fd3eff4f5b62537db"

    path = ["user", 42, "keys"]
    empty_path = []

    urn_path = ["doma", "e7c7ec7d56197de97f9a73ae20d9672e99aebd48922a3d4fd3eff4f5b62537db"]

    query = %{1 => :"get all data", :foo => "bar"}
    empty_query = %{}

    fragment = "key-1"
    empty_fragment = ""

    full_url = %{
      protocol: protocol,
      fqdn: fqdn,
      port: port,
      path: path,
      query: query,
      fragment: fragment
    }

    assert(
      DoAuth.URI.url2s(full_url) ==
        "https://test.aaa.doma.dev:8443/user/42/keys?1=get+all+data&foo=bar#key-1"
    )

    partial_url_1 = %{
      protocol: protocol,
      fqdn: fqdn,
      port: nil_port,
      path: empty_path,
      query: query,
      fragment: fragment
    }

    assert(
      DoAuth.URI.url2s(partial_url_1) ==
        "https://test.aaa.doma.dev?1=get+all+data&foo=bar#key-1"
    )

    partial_url_2 = %{
      protocol: protocol,
      fqdn: fqdn,
      port: port,
      path: path,
      query: empty_query,
      fragment: empty_fragment
    }

    assert(
      DoAuth.URI.url2s(partial_url_2) ==
        "https://test.aaa.doma.dev:8443/user/42/keys"
    )

    partial_url_3 = %{
      protocol: protocol,
      fqdn: fqdn
    }

    assert(
      DoAuth.URI.url2s(partial_url_3) ==
        "https://test.aaa.doma.dev"
    )

    full_urn = %{
      scheme: scheme,
      path: urn_path,
      query: query,
      fragment: fragment
    }

    did_matching_urn = %{
      method: method,
      id: did_id,
      query: query,
      fragment: fragment
    }

    assert(DoAuth.URI.urn2s(full_urn) == DoAuth.URI.did2s(did_matching_urn))

    assert(
      DoAuth.URI.urn2s(full_urn) ==
        "did:doma:e7c7ec7d56197de97f9a73ae20d9672e99aebd48922a3d4fd3eff4f5b62537db?1=get+all+data&foo=bar#key-1"
    )

    full_did = did_matching_urn |> Map.put_new(:path, path)

    assert(
      DoAuth.URI.did2s(full_did) ==
        "did:doma:e7c7ec7d56197de97f9a73ae20d9672e99aebd48922a3d4fd3eff4f5b62537db/user/42/keys?1=get+all+data&foo=bar#key-1"
    )
  end

  test "can store and encode issuer URLs" do
    id = 42

    issuer =
      URI.parse("https://vc.www.w3.org:8443/issuers/{}")
      |> DoAuth.URI.uri2url()
      |> DoAuth.Credential.Issuer.from_url(id)
      |> DoAuth.Credential.Issuer.to_string()

    assert(issuer == "https://vc.www.w3.org:8443/issuers/42")
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
