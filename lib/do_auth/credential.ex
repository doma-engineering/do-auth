defmodule DoAuth.Credential do
  @moduledoc """
  VC-inspired claim data structure.

  So far we're not bothering ourselves with contexts, but some day we will
  support contexts too for better discoverability.
  """

  use TypedStruct

  # TODO: make doauthcredential context
  typedstruct do
    field(:"@context", nonempty_list(String.t()),
      default: ["https://www.w3.org/2018/credentials/v1"]
    )

    field(:id, pos_integer(), enforce: true)

    field(:type, nonempty_list(list(String.t())),
      default: ["VerifiableCredential", "DoauthCredential"]
    )

    field(:issuer, DoAuth.Credential.Entity.t(), enforce: true)
    field(:issuanceDate, DateTime.t(), enforce: true)
    field(:credentialSubject, DoAuth.Claim.Subject.t(), enforce: true)
    field(:proof, DoAuth.Claim.Proof.t(), enforce: true)
  end
end
