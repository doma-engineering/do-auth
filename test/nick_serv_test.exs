defmodule NickServTest do
  @moduledoc """
  Testing nickserver!
  """
  use DoAuth.DataCase
  use DoAuth.Boilerplate.DatabaseStuff
  use DoAuth.Test.Support.Fixtures, [:crypto]
  alias DoAuth.{NickServ}
  alias DoAuth.Repo.Populate

  describe "in NickServ" do
    setup do
      {:ok, _} = Populate.populate_do()
      :ok
    end

    test "nicks can be registered" do
      registrant_kp = %{public: rpk} = signing_key_id_1_fixture()
      {:ok, did} = DID.sin_one_pk(rpk)
      did64 = DID.to_string(did)

      {:ok, req_vc} =
        Credential.transact_with_keypair_from_subject_map(registrant_kp, %{"nickname" => "jonn"})

      req_vc_map = Credential.to_map(req_vc)

      {:ok, _x} = NickServ.register64(req_vc_map)

      assert(NickServ.whois_nickname("jonn") == {:ok, did64})
      assert(NickServ.whois_did64(did64) == {:ok, "jonn"})
    end
  end
end
