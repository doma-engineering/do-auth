defmodule CredentialCryptoTest do
  use DoAuth.DataCase
  use DoAuth.Boilerplate.DatabaseStuff
  use DoAuth.Test.Support.Fixtures, [:crypto]
  alias DoAuth.{Crypto, Presentation}

  test "credential unwraps misc fields correctly" do
    cred_map = mk_cred_map()
    [tau0, tau1, tau2] = taus()
    m = &Map.get(cred_map, &1)
    assert("/fact/1" == m.("id"))
    {:ok, issuance_date, 0} = m.("issuanceDate") |> DateTime.from_iso8601()
    assert(tau0 == issuance_date)
    {:ok, valid_from, 0} = m.("validFrom") |> DateTime.from_iso8601()
    assert(tau1 == valid_from)
    {:ok, valid_until, 0} = m.("validUntil") |> DateTime.from_iso8601()
    assert(tau2 == valid_until)
  end

  test "credentials are verifiable maps" do
    {:ok, true} = mk_cred_map() |> Crypto.verify_map()
  end

  test "credential presentations are verifiable maps" do
    kp = signing_key_fixture(Enum.random(0..32))
    {:ok, _did} = DID.sin_one_pk(kp.public)
    {:ok, presentation_map} = Presentation.present_credential_map(kp, mk_cred_map())
    {:ok, true} = presentation_map |> Crypto.verify_map()
  end

  @spec taus() :: list(DateTime.t())
  def taus() do
    [
      Repo.from_utc_iso8601!("1989-12-21T13:37:00Z"),
      Repo.from_utc_iso8601!("1995-09-01T08:30:00Z"),
      Repo.from_utc_iso8601!("2008-08-31T23:59:59Z")
    ]
  end

  @spec mk_cred_map() :: map()
  def mk_cred_map() do
    kp = signing_key_fixture(Enum.random(0..32))
    {:ok, _did} = DID.sin_one_pk(kp.public)
    [tau0, tau1, tau2] = taus()

    Credential.transact_with_keypair_from_subject_map!(
      kp,
      %{"doma" => "good"},
      %{
        "location" => "/fact/1",
        "validFrom" => tau1,
        "validUntil" => tau2
      },
      timestamp: tau0
    )
    |> Credential.to_map()
  end
end
