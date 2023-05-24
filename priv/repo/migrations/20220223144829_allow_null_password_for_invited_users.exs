defmodule Mayday.Repo.Migrations.AllowNullPasswordForInvitedUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :hashed_password, :string, null: true
    end

    create constraint(:users, :confirmed_must_have_password,
             check: "NOT (confirmed_at = null AND hashed_password = null)"
           )
  end

  def down do
    alter table(:users) do
      modify :hashed_password, :string, null: false
    end

    drop constraint(:users, :confirmed_must_have_password)
  end
end
