defmodule Mayday.Repo.Migrations.RenameSponsorToState do
  use Ecto.Migration

  def change do
    rename table(:actions), :sponsor, to: :state
    rename table(:actions), :sponsor_details, to: :sponsor

    drop constraint(:actions, :other_sponsor_must_have_details,
           check: "num_nonnulls(sponsor, sponsor_details) = 1"
         )
  end
end
