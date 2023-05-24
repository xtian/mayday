defmodule Mayday.Repo.Migrations.ChangeEndsAtToTime do
  use Ecto.Migration

  def change do
    drop constraint(:actions, :starts_at_must_be_before_ends_at)

    alter table(:actions) do
      modify :ends_at, :time
    end
  end
end
