defmodule DoAuthWeb.Users.NickServView do
  use DoAuthWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{fulfillment: fulfillment}) do
    fulfillment
  end

  def render("403.json", e) do
    e = e |> Map.delete(:conn)
    %{"error" => "invalid credential", "info" => e}
  end
end
