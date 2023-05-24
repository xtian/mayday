defmodule Mayday.Repo.Migrations.AddTelnyxNumbers do
  use Ecto.Migration

  def change do
    create table(:provisioned_numbers, primary_key: false) do
      add :phone_number, :string, null: false, primary_key: true
    end

    alter table(:campaigns) do
      add :phone_number,
          references(:provisioned_numbers,
            on_delete: :restrict,
            column: :phone_number,
            type: :string
          ),
          null: false
    end

    create unique_index(:campaigns, [:phone_number], where: "started_at <> null")
  end
end
