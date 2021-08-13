defmodule DoAuthWeb.Trusts.TofuControllerTest do
  use DoAuthWeb.ConnCase
  use DoAuth.DataCase
  alias DoAuth.Repo.Populate

  # credo:disable-for-this-file

  describe "TOFU endpoint" do
    setup do
      {:ok, _} = Populate.populate_do()
      :ok
    end

    test "it works", %{conn: c} do
      ## This works
      # Populate.populate_do()
      c = get(c, "/tofu")
      assert 200 == c.status
    end
  end
end
