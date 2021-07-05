defmodule DoAuth.Repo.Migrations.RenameEntitiesToIssuers do
  use Ecto.Migration

  def change do
    rename table("entities"), to: table("issuers")
  end
end
