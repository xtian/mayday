defmodule Mayday.Repo.Migrations.ChangeStartsAtToNaiveDatetime do
  use Ecto.Migration

  def change do
    alter table(:actions) do
      modify :starts_at, :naive_datetime, from: :utc_datetime
    end
  end
end
