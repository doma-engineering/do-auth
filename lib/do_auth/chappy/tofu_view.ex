defmodule DoAuth.Chappy.TofuView do
  alias DoAuth.Credential

  def render("tofu.json", %{cred: cred, endpoint: endpoint}) do
    cred |> Credential.to_map(unwrapped: true) |> Map.put(:id, endpoint)
  end
end
