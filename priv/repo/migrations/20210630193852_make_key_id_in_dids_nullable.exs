defmodule DoAuth.Repo.Migrations.MakeKeyIdInDidsNullable do
  use Ecto.Migration

  def change do
    alter table(:dids) do
      modify :key_id, :integer, null: true
    end
  end
end
