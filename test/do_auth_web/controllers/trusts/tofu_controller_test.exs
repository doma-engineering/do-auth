defmodule DoAuthWeb.Trusts.TofuControllerTest do
  use DoAuthWeb.ConnCase
  use DoAuth.DataCase
  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.Repo.Populate
  alias DoAuth.Crypto

  # credo:disable-for-this-file

  describe "TOFU endpoint" do
    setup do
      {:ok, _} = Populate.populate_do()
      :ok
    end

    test "works", %{conn: c} do
      ## This works
      # Populate.populate_do()
      c = get(c, "/tofu")
      assert 200 == c.status
    end

    test "returns a credential that has the PK", %{conn: c} do
      c = get(c, "/tofu")
      %{public: pk} = Crypto.server_keypair64()
      me = Map.get(c, :assigns) |> Map.get(:tofu) |> Map.get("credentialSubject") |> Map.get("me")
      assert me == pk
    end

    test "returns a valid credential", %{conn: c} do
      c = get(c, "/tofu")
      cred_map = Map.get(c, :assigns) |> Map.get(:tofu)
      assert {:ok, true} == Crypto.verify_map(cred_map)
    end
  end
end
