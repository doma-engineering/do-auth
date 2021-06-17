defmodule DoAuth.Repo.Migrations.AddUrl do
  use Ecto.Migration

  def change do
     
    rename table("issuers"), to: table("urls")

    rename table("entities"), :issuer_id, to: :url_id

  end  
end
