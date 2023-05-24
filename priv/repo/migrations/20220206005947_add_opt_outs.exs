defmodule Mayday.Repo.Migrations.AddOptOuts do
  use Ecto.Migration

  def change do
    create table(:opt_outs, primary_key: false) do
      add :hash, :string, null: false, primary_key: true
      timestamps(updated_at: false)
    end
  end
end
