defmodule DoAuth.DID do
  @moduledoc """
  DID structure, capturing method, and DID URL params.
  """

  alias DoAuth.URI

  use TypedStruct

  typedstruct do
    field(:method, String.t(), default: "doma")
    field(:id, Stirng.t(), enforce: true)
    field(:path, URI.path())
    field(:query, URI.query())
    field(:fragment, URI.fragment())
  end
end
