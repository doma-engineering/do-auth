defmodule DoAuth.Chappy.ChappyView do
  @spec render(<<_::80, _::_*16>>, %{:token => any, optional(any) => any}) :: %{
          ok: %{optional(:cont) => any, optional(:start) => any}
        }
  def render("success.json", %{token: token}) do
    %{ok: %{start: token}}
  end

  def render("chain.json", %{token: token}) do
    %{ok: %{cont: token}}
  end
end
