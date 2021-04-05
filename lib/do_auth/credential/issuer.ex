defmodule DoAuth.Credential.Issuer do
  @moduledoc """
  Issuer URL: somewhere where a verifier can get some information about an
  entity it's not aware of.
  """
  alias DoAuth.URI

  use TypedStruct

  typedstruct do
    field(:protocol, String.t(), default: "https://")
    field(:fqdn, String.t(), enforce: true)
    field(:port, pos_integer())
    field(:path, URI.path(), enforce: true)
    field(:id, pos_integer(), enforce: true)
    field(:query, URI.query())
    field(:fragment, URI.fragment())
  end

  @spec from_url(URI.url(), pos_integer()) :: __MODULE__.t() | nil
  def from_url(u, i) do
    if(URI.url2s(u) =~ URI.mts("{}")) do
      from_url!(u, i)
    else
      nil
    end
  end

  @spec from_url!(URI.url(), pos_integer()) :: __MODULE__.t()
  def from_url!(
        %{
          protocol: protocol,
          fqdn: fqdn,
          port: port,
          path: path,
          query: query,
          fragment: fragment
        },
        id
      ) do
    %__MODULE__{
      id: id,
      protocol: protocol,
      fqdn: fqdn,
      port: port,
      path: path,
      query: query,
      fragment: fragment
    }
  end

  @spec to_string(__MODULE__.t()) :: String.t()
  def to_string(m = %__MODULE__{id: id}) do
    m
    |> Map.from_struct()
    |> DoAuth.URI.url2s()
    |> String.replace(URI.mts("{}"), "#{inspect(id)}")
  end
end
