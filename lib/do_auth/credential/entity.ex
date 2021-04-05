defmodule DoAuth.Credential.Entity do
  @moduledoc """
  Either a DID or issuer URL with ID
  """
  @type t :: DoAuth.DID.t() | DoAuth.Credential.Issuer.t()
end
