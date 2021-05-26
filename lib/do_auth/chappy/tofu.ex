defmodule DoAuth.Chappy.Tofu do
  @moduledoc """
  This module is dedicated to assisting clients in getting introduced to doauth servers.
  We are inspired by TOFU, just as Gemini protocol is:

  https://drewdevault.com/2020/09/21/Gemini-TOFU.html
  """

  use Phoenix.Controller, namespace: DoAuth.Web
  # import Plug.Conn
  alias DoAuth.Chappy.TofuView, as: View
  alias DoAuth.Crypto
  alias DoAuth.Subject
  alias DoAuth.Credential

  def init(x), do: x

  def me(c, _) do
    # TODO: Key management is kinda meh, we leave traces of secret key all over
    # the memory
    %{public: pk} = Crypto.server_keypair()
    cred = Subject.by_claim_me(pk |> Crypto.show()) |> Credential.by_subject()
    c |> put_view(View) |> render("tofu.json", %{cred: cred, endpoint: "/chappy/tofu"})
  end
end
