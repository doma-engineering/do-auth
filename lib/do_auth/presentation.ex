defmodule DoAuth.Presentation do
  @moduledoc """
  Wraps credentials. It's useful both as a privacy control and as a sort of challenge-response.

  It prevents replay attacks in single-use invites, for example.

  Perhaps, in the later versions it would make sense to promote Presentation to Schema and persist some, but we don't need it at the moment.
  """

  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.{Crypto}

  @spec verify_presentation_map(map()) :: {:error, any} | {:ok, true}
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
        ) :: map()
  def present_credential(%{public: pk} = kp, %Credential{} = credential, opts \\ []) do
    try do
      issuer = DID.one_by_pk!(pk)
      presentation_so_far = %{"verifiableCredential" => credential, "issuer" => issuer}

      presentation_so_far =
        if opts[:holder] do
          %{presentation_so_far | "holder" => opts[:holder]}
        else
          presentation_so_far
        end

      Crypto.sign_map!(kp, presentation_so_far, opts)
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
    end
  end
end
