[
  defmodule DoAuthTest do
    use DoAuth.RepoCase
    use DoAuth.DBUtils

    doctest DoAuth

    alias DoAuth.Crypto

    @pass_iolist ["tiny🏯", "grasshōpper👹"]
    @pass_binary "tiny🏯grasshōpper👹"

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

    test "signatures are tripping" do
      with {mkey, _} <- Crypto.main_key_init(@pass_iolist, very_weak_params()) do
        msg = ["hello", " ", "world"]
        keypair = Crypto.derive_signing_keypair(mkey, 1)
        %{public: pk, signature: sig} = Crypto.sign(msg, keypair)

        assert(
          Crypto.verify(msg, %{public: pk, signature: sig |> Crypto.show() |> Crypto.read!()})
        )
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
        body: did_id,
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

    defp salt() do
      <<100, 32, 150, 98, 22, 128, 99, 12, 9, 72, 154, 27, 204, 213, 183, 48>>
    end

    test "URLSAFE Base64 matches libsodium.js version" do
      # sodium.to_base64(salt, sodium.base64_variants["URLSAFE"])
      # "ZCCWYhaAYwwJSJobzNW3MA=="
      assert("ZCCWYhaAYwwJSJobzNW3MA==" == salt() |> DoAuth.Crypto.show())
    end

    test "mkey matches libsodium.js version" do
      # https://social.doma.dev/system/media_attachments/files/000/007/810/original/0b72a236b039d104.png?1621640300
      mkey = :enacl.pwhash("powo cutie", salt(), 4, 40960)

      assert("l1nP-RQlLUB981ym41E-YoxSa-qdN4kPdWje-s1U2jo=" == mkey |> Crypto.show())
    end

    test "proofless JSON is the same between JS and Elixir" do
      alias DoAuth.Credential

      cred_map =
        ~s({"@context":[],"credentialSubject":{"me":"oV4kXLoRS79WUk5rTbLxlsujYDWeAe7E6QeDyIWOYbA="},"id":"/chappy/tofu","issuanceDate":"2021-05-26T16:14:50Z","issuer":"did:doma:c5Cfk0Aw_SYXzIgvDO3QNumrD30E5o-Sd61n8bL4dTw=","proof":{"created":"2021-05-26T16:14:50Z","proofPurpose":"assertionMethod","signature":"tpjEnvT3PdSq8Z0I6Qii9z8x5nIE3f3nO9rqzaAdonDG9z5fyw_hWSMi1jjAGmMJtkJkvRpZ_hbU7C0WPwtMD1tbIkBjb250ZXh0IixbXV0sWyJjcmVkZW50aWFsU3ViamVjdCIsW1sibWUiLCJvVjRrWExvUlM3OVdVazVyVGJMeGxzdWpZRFdlQWU3RTZRZUR5SVdPWWJBPSJdXV0sWyJpc3N1YW5jZURhdGUiLCIyMDIxLTA1LTI2VDE2OjE0OjUwWiJdLFsiaXNzdWVyIiwiZGlkOmRvbWE6YzVDZmswQXdfU1lYeklndkRPM1FOdW1yRDMwRTVvLVNkNjFuOGJMNGRUdz0iXSxbInR5cGUiLFtdXV0=","type":"libsodium2021","verificationMethod":"did:doma:c5Cfk0Aw_SYXzIgvDO3QNumrD30E5o-Sd61n8bL4dTw="},"type":[]})
        |> Jason.decode!(keys: :atoms)

      cred = Credential.tx_import_tofu!(cred_map)

      assert(
        ~s([["@context",[]],["credentialSubject",[["me","oV4kXLoRS79WUk5rTbLxlsujYDWeAe7E6QeDyIWOYbA="]]],["issuanceDate","2021-05-26T16:14:50Z"],["issuer","did:doma:c5Cfk0Aw_SYXzIgvDO3QNumrD30E5o-Sd61n8bL4dTw="],["type",[]]]) ==
          Credential.proofless_json(cred)
      )

      assert(Credential.verify64(cred, cred.subject.claim["me"]))
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
]
