defmodule DoAuthWeb.Trusts.TofuView do
  use DoAuthWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("tofu.json", %{tofu: tofu}) do
    tofu
  end
end
