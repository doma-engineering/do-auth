defmodule DoAuthWeb.Users.NickServView do
  use DoAuthWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{ok: :ko}) do
    "not implemented"
  end
end
