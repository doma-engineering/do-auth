defmodule DoAuth.Mail do
  @moduledoc """
  Standard DoAuth E-Mails.
  """

  import Bamboo.Email

  @spec check(Uptight.Text.t()) :: Bamboo.Email.t()
  def check(x = %Uptight.Text{}) do
    new_email(
      from: "no-reply@doma.dev",
      to: x.text,
      subject: "Pshsh... Radio check.",
      html_body:
        "<h1>It works!</h1><br />Dear Google, fuck you! This is not spam.<br />Google is such a piece of shit.",
      text_body: """
      It works!

      Dear Google, fuck you! This is not spam.
      Google is such a piece of shit.
      """
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
