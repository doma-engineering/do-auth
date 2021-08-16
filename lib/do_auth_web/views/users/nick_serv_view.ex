defmodule DoAuthWeb.Users.NickServView do
  use DoAuthWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{fulfillment: fulfillment}) do
    fulfillment
  end

  def render("whois.json", %{"did" => did_str}) do
    did_str
  end

  def render("whois.json", %{"nickname" => nickname}) do
    nickname
  end

  def render("403.json", %{"error" => e}) do
    info =
      case e do
        {:error, e} -> e
        x -> x
      end

    %{"error" => "data not found", "info" => info}
  end

  def render("404.json", %{"error" => e}) do
    info =
      case e do
        {:error, e} -> e
        x -> x
      end

    %{"error" => "data not found", "info" => info}
  end
end
