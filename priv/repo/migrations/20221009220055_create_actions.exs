defmodule Mayday.Repo.Migrations.CreateActions do
  use Ecto.Migration

  def change do
    create table(:actions) do
      add :address, :string
      add :approved_at, :utc_datetime
      add :comment, :string
      add :cost_to_attend, :decimal
      add :description, :string
      add :title, :string, null: false
      add :url, :string

      add :sponsor, :string
      add :sponsor_details, :string

      add :submitter_email, :string
      add :submitter_name, :string

      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime

      timestamps()
    end

    create constraint(:actions, :cost_to_attend_must_be_positive, check: "cost_to_attend > 0")

    create constraint(:actions, :location_or_url_must_be_non_null,
             check: "num_nonnulls(address, url) > 0"
           )

    create constraint(:actions, :other_sponsor_must_have_details,
             check: "num_nonnulls(sponsor, sponsor_details) = 1"
           )

    create constraint(:actions, :starts_at_must_be_before_ends_at, check: "starts_at < ends_at")
  end
end
