defmodule DoAuth.Schema.URL do
  @moduledoc """
  Tracks issuer URLs.
  """
  use DoAuth.Boilerplate.DatabaseStuff

  schema "urls" do
    field(:url, :string)
    has_one(:entity, Issuer)
  end

  @spec to_string(%__MODULE__{}, list) :: String.t()
  def to_string(%__MODULE__{url: url}, _opts \\ []) do
    url
  end

  @spec to_map(%__MODULE__{}, list) :: map
  def to_map(%__MODULE__{url: url}, _opts \\ []) do
    url
  end
end
