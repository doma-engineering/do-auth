defmodule DoAuthTest do
  use ExUnit.Case
  doctest DoAuth

  test "has secret key base set" do
    assert(
      Application.get_env(:do_auth, DoAuth.Web)
      |> Keyword.fetch!(:secret_key_base) == "do-auth-test-key-base"
    )
  end
end
