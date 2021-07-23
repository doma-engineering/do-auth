defmodule DoAuth.Presentation do
  @moduledoc """
  Wraps credentials. It's useful both as a privacy control and as a sort of challenge-response.

  It prevents replay attacks in single-use invites, for example.

  Perhaps, in the later versions it would make sense to promote Presentation to Schema and persist some, but we don't need it at the moment.
  """

  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.{Crypto, Cat}

  @spec verify_presentation_map(map()) :: {:error, any} | {:ok, boolean()}
  def verify_presentation_map(presentation_map) do
    Crypto.verify_map(presentation_map)
  end

  @doc """
  To prepare presentation for someone, add `holder: some_did` to the opts list.
  This `some_did` value doesn't have to be registered with us.

  Same as with any function that takes keypair with an optional secret key (type Crypto.keypair_opt()), you can provide signature in the `opts` field which shall be inserted into the verifiable presentation verbatim, without post-verification.
  """
  @spec present_credential(
          Crypto.keypair_opt(),
          %Credential{},
          list()
        ) :: {:ok, map()} | {:error, any()}
  def present_credential(kp, %Credential{} = credential, opts \\ []) do
    present_credential_map(kp, credential |> Credential.to_map(), opts)
  end

  @spec present_credential_map(
          Crypto.keypair_opt(),
          map(),
          list()
        ) :: {:ok, map()} | {:error, any()}
  def present_credential_map(%{public: pk} = kp, %{} = credential_map, opts \\ []) do
    try do
      p = &Cat.put_new_value(&1, &2, &3)
      o = &Keyword.get(opts, &1)
      issuer = DID.one_by_pk!(pk)

      presentation_claim =
        %{
          "verifiableCredential" => credential_map,
          "issuer" => issuer |> DID.to_string()
        }
        |> p.("id", o.(:location))
        |> p.("holder", o.(:holder))

      {:ok, Crypto.sign_map!(kp, presentation_claim, opts)}
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
    end
  end
end
