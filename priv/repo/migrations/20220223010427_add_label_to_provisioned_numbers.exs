defmodule Mayday.Repo.Migrations.AddLabelToProvisionedNumbers do
  use Ecto.Migration

  def up do
    alter table(:provisioned_numbers) do
      add :label, :string
    end

    flush()
    repo.update_all("provisioned_numbers", set: [label: "Outgoing Number"])

    alter table(:provisioned_numbers) do
      modify :label, :string, null: false
    end
  end

  def down do
    alter table(:provisioned_numbers) do
      remove :label, :string
    end
  end
end
