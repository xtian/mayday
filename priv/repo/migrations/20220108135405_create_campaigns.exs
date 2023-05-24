defmodule Mayday.Repo.Migrations.CreateCampaigns do
  use Ecto.Migration

  def change do
    create table(:campaigns) do
      add :completed_at, :utc_datetime
      add :name, :string, null: false
      add :script_messages, :map, null: false
      add :started_at, :utc_datetime

      timestamps()
    end

    create table(:conversations) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :completed_at, :utc_datetime
      add :contact_id, references(:contacts, on_delete: :delete_all), null: false
      add :survey_responses, :map, null: false
      add :last_message_at, :utc_datetime
      add :last_read_at, :utc_datetime
      add :started_at, :utc_datetime
      add :user_id, references(:users)

      timestamps()
    end

    create table(:messages) do
      add :body, :text, null: false
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :contact_id, references(:contacts, on_delete: :delete_all)
      add :user_id, references(:users)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:conversations, [:campaign_id, :contact_id], where: "contact_id = null")
    create index(:conversations, [:campaign_id, :user_id])

    create constraint(:messages, :relates_to_one_sender,
             check: """
             (contact_id <> null AND user_id = null)
             OR
             (contact_id = null AND user_id <> null)
             """
           )
  end
end
