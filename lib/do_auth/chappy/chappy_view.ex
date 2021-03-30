defmodule DoAuth.Chappy.ChappyView do
  def render("success.json", %{token: token}) do
    %{ok: %{start: token}}
  end

  def render("chain.json", %{token: token}) do
    %{ok: %{cont: token}}
  end
end
