defmodule DoAuth.URI do
  @moduledoc """
  DoAuth URI builder.
  Uses Elixir's URI module here and there.
  Such low tech, much convenience.

  TODO: Support more of RFC3986, for example authority, etc.
  """

  @typedoc """
  Path from RFC3986.
  """
  @type path :: list(any())

  @typedoc """
  Query from RFC3986.
  """
  @type query :: %{String.t() => String.t()}

  @typedoc """
  Fragment from RFC3986.
  """
  @type fragment :: String.t()

  @typedoc """
  Type capturing URL URIs.
  """
  @type url :: %{
          required(:protocol) => String.t(),
          required(:fqdn) => String.t(),
          optional(:port) => pos_integer(),
          optional(:path) => path(),
          optional(:query) => query(),
          optional(:fragment) => fragment()
        }
  @typedoc """
  Type capturing URN URIs.

  Note: path here MUST be joined with ':', whereas path in did type MUST be
  joined with '/' and prefixed with '/'. This is an underinvestigated (by us)
  aspect of DID standard. AFAWU, RFC3986 specifies that in case of URNs path
  is the tail of the hierarchy after the scheme identifier.

  TODO: check if URNs can have slash-paths.
  """
  @type urn :: %{
          required(:scheme) => String.t(),
          required(:path) => path(),
          optional(:query) => query(),
          optional(:fragment) => fragment()
        }
  @typedoc """
  Type capturing DID URIs.

  Note: path here MUST be joined with '/', and prefixed with '/', whereas in
  urn type, it should be joined with ':'. This is an underinvestigated (by
  us) aspect of DID standard. AFAWU, RFC3986 specifies that in case of URNs
  path is the tail of the hierarchy after the scheme identifier.
  """
  @type did ::
          %{
            required(:method) => String.t(),
            required(:body) => String.t(),
            optional(:path) => path(),
            optional(:query) => query(),
            optional(:fragment) => fragment()
          }
          | %DoAuth.Schema.DID{}
          | any()

  @doc """
  Nillable maybe slash-based path to www-string.
  """
  @spec p(nil | path()) :: String.t()
  def p(nil), do: ""
  def p([]), do: ""
  def p(path), do: "/" <> www_join(path, "/")

  @doc """
  Nillable maybe colon-based path to www-string.

  (As seen in URNs)
  """
  @spec np(nil | path()) :: String.t()
  def np(nil), do: ""
  def np([]), do: ""
  def np(path), do: ":" <> www_join(path, ":")

  @doc """
  Nillable maybe port renderer
  """
  @spec pt(nil | pos_integer()) :: String.t()
  def pt(nil), do: ""
  def pt(p), do: ":" <> mts(p)

  @doc """
  Nillable maybe query map to www-query-string.
  """
  @spec q(nil | query()) :: String.t()
  def q(nil), do: ""
  def q(m) when m == %{}, do: ""

  def q(query) do
    "?" <> URI.encode_query(query)
  end

  @doc """
  Fragment to www-string.
  """
  @spec f(nil | fragment()) :: String.t()
  def f(nil), do: ""
  def f(""), do: ""
  def f(x), do: "#" <> mts(x)

  @doc """
  Nillable maybe to www-string.
  """
  @spec mts(any()) :: String.t()
  def mts(nil), do: ""
  def mts(x) when is_binary(x), do: URI.encode_www_form(x)
  def mts(x), do: x |> inspect() |> URI.encode_www_form()

  @doc """
  URL to string.
  """
  @spec url2s(url()) :: String.t()
  def url2s(
        %{
          protocol: protocol,
          fqdn: fqdn
        } = m
      ) do
    "#{protocol}://#{fqdn}#{pt(m[:port])}#{p(m[:path])}#{q(m[:query])}#{f(m[:fragment])}"
  end

  @doc """
  URN to string.
  """
  @spec urn2s(urn()) :: String.t()
  def urn2s(%{scheme: scheme, path: path} = m) do
    "#{scheme}#{np(path)}#{q(m[:query])}#{f(m[:fragment])}"
  end

  @doc """
  DID to string.
  """
  @spec did2s(did()) :: String.t()
  def did2s(%{method: method, body: body} = m) do
    "did:#{method}:#{body}#{p(m[:path])}#{q(m[:query])}#{f(m[:fragment])}"
  end

  @doc """
  Convert Elixir URI to DoAuth URL.
  """
  @spec uri2url(URI.t()) :: url()
  def uri2url(%URI{host: fqdn, scheme: protocol} = ex_uri) do
    with url <-
           ex_uri
           |> Map.from_struct()
           |> Map.put_new(:fqdn, fqdn)
           |> Map.put_new(:protocol, protocol) do
      %{url | path: url[:path] |> String.split("/") |> drop_empty()}
    end
  end

  defp drop_empty(xs) do
    xs |> Enum.filter(&(&1 != ""))
  end

  @doc """
  Www-encode a list of inspectables and join with a delimiter.
  """
  @spec www_join(list(any()), String.t()) :: String.t()
  def www_join(xs, delim),
    do: xs |> Enum.map(&mts(&1)) |> Enum.join(delim)
end
