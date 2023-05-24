defmodule Mayday.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :first_name, :string, null: false
      add :last_name, :string
      add :phone_number, :text, null: false

      timestamps()
    end

    create index(:contacts, [:last_name, :first_name])
    create unique_index(:contacts, :phone_number)

    create constraint(:contacts, :phone_number_must_be_valid,
             check: "phone_number ~ '^[0-9]{10}$'"
           )
  end
end
