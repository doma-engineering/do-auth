defmodule DoAuth.Credential.Proof do
  @moduledoc """
  A data structure and functions for lightweight proofs.

  Note: it's currently relying on DoAuth's libsodium wrapper and is NOT
  standard-compliant.

  Note: JWS for signature serialisation is not yet supported.
  """

  use TypedStruct

  @typedoc """
  The two proof purposes from W3 Verifiable Credentials standard.
  Source: https://www.w3.org/2018/credentials/v1
  """
  @type proof_purpose :: :assertionMethod | :authentication

  typedstruct do
    field(:type, String.t(), default: "LibsodiumSignature2021")
    field(:created, DateTime.t(), enforce: true)
    field(:proofPurpose, proof_purpose(), enforce: true)
    field(:verificationMethod, DoAuth.Credential.Entity.t(), enforce: true)
    field(:signature, Crypto.detached_sig(), enforce: true)
  end
end
