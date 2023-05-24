defmodule Mayday.Repo.Migrations.AddUsersRole do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, null: false
    end
  end
end
