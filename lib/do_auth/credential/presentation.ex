defmodule DoAuth.Credential.Presentation do
  @moduledoc """
  Verifiable presentation data structure and functions.

  Basically, replay-resistant VC representation.

  Note: it's currently relying on Chappy challenge mechanism and is NOT
  standard-compliant.
  """

  use TypedStruct

  typedstruct do
    field(:credential, DoAuth.Credential.t(), enforce: true)
    field(:challenge, %{chappy_token: binary()}, enforce: true)
    field(:proof, DoAuth.Credential.Proof.t(), enforce: true)
  end
end
