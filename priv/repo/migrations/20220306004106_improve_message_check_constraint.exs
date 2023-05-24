defmodule Mayday.Repo.Migrations.ImproveMessageCheckConstraint do
  use Ecto.Migration

  def up do
    drop constraint(:messages, :relates_to_one_sender)

    create constraint(:messages, :relates_to_one_sender,
             check: "num_nonnulls(contact_id, user_id) = 1"
           )
  end

  def down do
  end
end
