defmodule DoAuth.Chappy.InviteView do
  alias DoAuth.Credential

  def render("fulfill.json", %{fulfillment: fulfillment, grant: grant}) do
    %{
      echo:
        Jason.encode!(%{
          fulfillment: fulfillment |> Credential.to_map(unwrapped: true),
          grant: grant |> Credential.to_map(unwrapped: true)
        })
    }
  end
end
