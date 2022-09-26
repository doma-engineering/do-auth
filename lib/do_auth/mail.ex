defmodule DoAuth.Mail do
  @moduledoc """
  Standard DoAuth E-Mails.
  """

  import Bamboo.Email
  import Witchcraft.Functor

  alias Uptight.Base
  alias Uptight.Text, as: T
  alias Uptight.Fold

  defp noreply(to, subject, html, text) do
    new_email(
      from: "no-reply@doma.dev",
      to: to.text,
      subject: subject.text,
      html_body: html.text,
      text_body: text.text
    )
  end

  @spec confirmation(Base.t(), T.t(), T.t(), keyword(T.t() | list(T.t()))) ::
          Bamboo.Email.t()
  def confirmation(secret, email, nickname, opts \\ []) do
    require Logger

    homebase_fqdn = opts[:homebase] || "localhost" |> T.new!()

    scheme =
      (homebase_fqdn.text == "localhost" && "http" |> T.new!()) ||
        (opts[:scheme] || "https" |> T.new!())

    public_prefix = opts[:public_prefix] || "public" |> T.new!()
    public_prefix = (is_list(public_prefix) && public_prefix) || [public_prefix]

    endpoint =
      opts[:endpoint] ||
        ["doauth", "confirm"]
        |> map(&T.new!/1)

    port = (opts[:port] != nil && String.to_integer(opts[:port].text)) || nil

    _endpoint_str = Fold.intercalate(public_prefix ++ endpoint, T.new!("/"))
    endpoint_path = Fold.intercalate([T.new!("") | endpoint], T.new!("/"))

    uri_str =
      %URI{
        scheme: scheme.text,
        host: homebase_fqdn.text,
        path: endpoint_path.text,
        port: port,
        query: URI.encode_query(%{"token" => secret.encoded, "email" => email.text})
      }
      |> URI.to_string()

    front_name = opts[:front_name] || "DoAuth" |> T.new!()

    html =
      """
      <h2>Welcome to #{front_name.text}!</h2>
      <div>Click <a href="#{uri_str}">here</a> to register as #{nickname.text}.</div>
      <br />
      <small>If you didn't register with #{homebase_fqdn.text}, ignore this E-Mail.</small>
      """
      |> T.new!()

    text =
      """
      Welcome to #{front_name.text}!
      ==================

      Follow #{uri_str} to register as #{nickname.text}.

      If you didn't register with #{homebase_fqdn.text}, ignore this E-Mail.
      """
      |> T.new!()

    noreply(
      email,
      "Welcome to #{front_name.text}, #{nickname.text}!" |> T.new!(),
      html,
      text
    )
  end
end
