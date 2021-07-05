defmodule DoAuth.Repo.Migrations.DropUniqueIndexForClaims do
  use Ecto.Migration

  def change do
    drop index(:subjects, [:claim])
  end
end
