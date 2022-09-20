defmodule DoAuth.Regression18Test do
  use Plug.Test
  use ExUnit.Case, async: true

  use DoAuth.TestFixtures, [:crypto]
  alias DoAuth.{Crypto, Credential}
  alias Uptight.Result

  test "verify map can fail on invalid credential" do
    valid_credential =
      Credential.mk_credential!(signing_key_fixture(10), %{"untampered" => "qwerty"})

    invalid_subject = valid_credential["credentialSubject"] |> Map.replace("untampered", "asd")
    invalid_credential = valid_credential |> Map.replace("credentialSubject", invalid_subject)
    assert Crypto.verify_map(invalid_credential) |> Result.is_err?()
  end
end
