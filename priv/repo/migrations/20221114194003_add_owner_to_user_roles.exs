defmodule Mayday.Repo.Migrations.AddOwnerToUserRoles do
  use Ecto.Migration

  import Ecto.Query

  def change do
    execute(
      fn -> "users" |> where(email: "hi@xtian.us") |> repo().update_all(set: [role: "owner"]) end,
      fn -> "users" |> where(email: "hi@xtian.us") |> repo().update_all(set: [role: "admin"]) end
    )
  end
end
