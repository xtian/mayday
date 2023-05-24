defmodule Mayday.Repo.Migrations.AddTags do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :contact_tag, :string
    end

    alter table(:contacts) do
      add :tags, {:array, :text}, default: [], null: false
    end

    create index(:contacts, [:tags], using: :gin)
  end
end
