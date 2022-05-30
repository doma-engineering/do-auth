defmodule DoAuth.Mail do
  @moduledoc """
  Standard DoAuth E-Mails.
  """

  import Bamboo.Email
  import Witchcraft.Functor

  alias Uptight.Base
  alias Uptight.Text
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

  @spec confirmation(Base.t(), Text.t(), Text.t(), Text.t(), keyword(Text.t() | list(Text.t()))) ::
          Bamboo.Email.t()
  def confirmation(secret, email, nickname, homebase_fqdn, opts \\ []) do
    scheme =
      (homebase_fqdn.text == "localhost" && "http" |> Text.new!()) ||
        (opts[:scheme] || "https" |> Text.new!())

    public_prefix = opts[:public_prefix] || "public" |> Text.new!()
    public_prefix = (is_list(public_prefix) && public_prefix) || [public_prefix]

    endpoint =
      opts[:endpoint] ||
        ["doauth", "confirm"]
        |> map(&Text.new!/1)

    endpoint_str = Fold.intercalate(public_prefix ++ endpoint, Text.new!("/"))

    uri_str =
      %URI{
        scheme: scheme.text,
        host: homebase_fqdn.text,
        path: "/doauth/confirm",
        query: URI.encode_query(%{"token" => secret.encoded})
      }
      |> URI.to_string()

    html =
      """
      <h2>Welcome to ZeroHR!</h2>
      <div>Click <a href="#{uri_str}">here</a> to register as #{nickname.text}.</div>
      <br />
      <small>If you didn't register with #{homebase_fqdn.text}, ignore this E-Mail.</small>
      """
      |> Text.new!()

    text =
      """
      Welcome to ZeroHR!
      ==================

      Follow #{uri_str} to register as #{nickname.text}.

      If you didn't register with #{homebase_fqdn.text}, ignore this E-Mail.
      """
      |> Text.new!()

    noreply(
      email,
      "Welcome to #{homebase_fqdn.text}, #{nickname.text}!" |> Text.new!(),
      html,
      text
    )
  end

  # @spec check() :: Bamboo.Email.t()
  # def check do
  #   new_email(
  #     from: "no-reply@doma.dev",
  #     to: "jm@memorici.de",
  #     subject: "Pshsh... Radio check.",
  #     html_body:
  #       "<h1>It works!</h1><br />Dear Google, fuck you! This is not spam.<br />Google is such a piece of shit.",
  #     text_body: """
  #     It works!

  #     Dear Google, fuck you! This is not spam.
  #     Google is such a piece of shit.
  #     """
  #   )
  # end
end
