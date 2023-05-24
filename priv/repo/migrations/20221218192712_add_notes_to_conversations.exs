defmodule Mayday.Repo.Migrations.AddNotesToConversations do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :notes, :text
    end
  end
end
