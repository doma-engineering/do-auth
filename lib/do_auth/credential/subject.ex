defmodule DoAuth.Credential.Subject do
  @moduledoc """
  Subject and subject matter data.
  """

  use TypedStruct

  typedstruct do
    field(:id, DoAuth.DID.t(), enforce: true)
    field(:claim, %{binary => any}, enforce: true)
  end
end
