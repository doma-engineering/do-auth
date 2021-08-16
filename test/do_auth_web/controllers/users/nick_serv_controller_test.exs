defmodule DoAuthWeb.Users.NickServControllerTest do
  @moduledoc """
  Tests that registered users can claim an alias.
  """

  use DoAuthWeb.ConnCase
  use DoAuth.DataCase
  use DoAuth.Boilerplate.DatabaseStuff
  use DoAuth.Test.Support.Fixtures, [:crypto]
  alias DoAuth.{Crypto, Repo.Populate}

  describe "NickServ endpoint" do
    setup do
      {:ok, _} = Populate.populate_do()
      :ok
    end

    test "can be used to register a nickname", %{conn: c} do
      {res, did_str} = insert_signing_key_1(c)
      assert "nickserv" == res |> Map.get("credentialSubject") |> Map.get("kind")

      assert did_str == res |> Map.get("credentialSubject") |> Map.get("holder")

      assert Crypto.verify_map(res)
    end

    test "whois endpoints work", %{conn: c} do
      {_res, did_str} = insert_signing_key_1(c)

      nickname =
        post(c, "/users/nickserv/whois", %{"did" => did_str})
        |> Map.get(:assigns)
        |> Map.get("nickname")

      assert("nickname" == nickname)

      did_str1 =
        post(c, "/users/nickserv/whois", %{"nickname" => "nickname"})
        |> Map.get(:assigns)
        |> Map.get("did")

      assert(did_str == did_str1)

      no_did = post(c, "/users/nickserv/whois", %{"did" => "non_existant"})

      assert 404 == no_did.status

      invalid = post(c, "/users/nickserv/whois", %{"did" => "invalid nickname"})

      assert 404 == invalid.status

      broken = post(c, "/users/nickserv/whois", %{"beep" => "boop"})

      assert 403 == broken.status
    end
  end

  defp insert_signing_key_1(c) do
    registrant_kp = %{public: rpk} = signing_key_id_1_fixture()
    {:ok, did} = DID.sin_one_pk(rpk)

    req_map =
      Credential.transact_with_keypair_from_subject_map!(registrant_kp, %{
        "nickname" => "nickname"
      })
      |> Credential.to_map()

    res =
      post(c, "/users/nickserv/register", %{"register" => req_map})
      |> Map.get(:assigns)
      |> Map.get(:fulfillment)

    did_str = DID.to_string(did)
    {res, did_str}
  end
end
