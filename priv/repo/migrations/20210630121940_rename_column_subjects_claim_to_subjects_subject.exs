defmodule DoAuth.Repo.Migrations.RenameColumnSubjectsClaimToSubjectsSubject do
  use Ecto.Migration

  def change do
    rename table("subjects"), :claim, to: :subject
  end
end
