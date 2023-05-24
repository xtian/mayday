defmodule Mayday.Repo.Migrations.AddIndexes do
  use Ecto.Migration

  def change do
    create index(:campaigns, [:started_at])
    create index(:messages, [:conversation_id])
  end
end
