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
      registrant_kp = %{public: rpk} = signing_key_id_1_fixture()
      {:ok, did} = DID.sin_one_pk(rpk)
      _did64 = DID.to_string(did)

      req_map =
        Credential.transact_with_keypair_from_subject_map!(registrant_kp, %{
          "nickname" => "nickname"
        })
        |> Credential.to_map()

      res =
        post(c, "/users/nickserv", %{"register" => req_map})
        |> Map.get(:assigns)
        |> Map.get(:fulfillment)

      assert "nickserv" == res |> Map.get("credentialSubject") |> Map.get("kind")

      assert DID.one_by_pk(rpk) |> DID.to_string() ==
               res |> Map.get("credentialSubject") |> Map.get("holder")

      assert Crypto.verify_map(res)
    end
  end
end
