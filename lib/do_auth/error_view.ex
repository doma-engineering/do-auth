defmodule DoAuth.ErrorView do
  use DoAuth.Web, :view
  def render("404.html", _), do: "i am empty"
  def render("500.html", _), do: "i glitched"
  def render("502.html", _), do: "i am alone"

  def template_not_found(t, _) do
    Phoenix.Controller.status_message_from_template(t)
  end
end
