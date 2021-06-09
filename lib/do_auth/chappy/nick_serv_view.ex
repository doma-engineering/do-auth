defmodule DoAuth.Chappy.NickServView do
  alias DoAuth.Credential
  # TODO: this stuff should really be abstracted away, but I can't be fucked.
  def render("register.json", %{nick_cert: cert}) do
    cert |> Credential.to_map()
  end
end
