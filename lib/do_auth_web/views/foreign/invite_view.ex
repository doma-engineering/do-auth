defmodule DoAuthWeb.Foreign.InviteView do
  use DoAuthWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{root: root}) do
    root
  end

  def render("403.json", e) do
    e = e |> Map.delete(:conn)
    %{"error" => "invalid presentation or invalid credential", "info" => e}
  end

  def render("500.json", e) do
    e = e |> Map.delete(:conn)
    %{"error" => "a problem with the server state", "info" => e}
  end
end
