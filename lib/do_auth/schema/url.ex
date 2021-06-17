defmodule DoAuth.URL do
  @moduledoc """
  Tracks issuer URLs.
  """
  use DoAuth.DBUtils, into: __MODULE__
  alias DoAuth.Entity

  schema "urls" do
    field(:url, :string)
    has_one(:entity, Entity)
  end

  @spec changeset(cauldron(), ingredients()) :: Changeset.t()
  def changeset(c, stuff) do
    DBUtils.castreq(c, stuff, :url)
  end

  @spec show(%DoAuth.URL{}) :: String.t()
  def show(x = %__MODULE__{}) do
    x.url
  end

  # TODO: figure out which approach to simple strings is better: this or the one currently used in key.ex!!!
  def to_map(url = %__MODULE__{}, unwrapped: true), do: url.url
  def to_map(x, []), do: to_map(x)
  def to_map(x), do: %{url: to_map(x, unwrapped: true)}

  DBUtils.codegen(into: __MODULE__)
end
