defmodule Mayday.Repo.Migrations.AddTagFilters do
  use Ecto.Migration

  import Ecto.Query

  alias Mayday.Campaigns.Campaign

  def change do
    alter table(:campaigns) do
      add :tag_filters, :map, null: false, default: "[]"
    end

    execute(
      fn ->
        for %{contact_tag: "" <> tag} = campaign <-
              Campaign
              |> select([:id, :name, :phone_number, :script_messages, :contact_tag])
              |> repo().all() do
          campaign
          |> Campaign.changeset(%{tag_filters: [%{tag: tag, direction: :include}]})
          |> repo().update!()
        end
      end,
      fn ->
        for %{tag_filters: [_ | _]} = campaign <-
              Campaign |> select([:id, :tag_filters]) |> repo().all() do
          tag = Enum.find(campaign.tag_filters, &(&1.direction == :include)).tag

          "campaigns" |> where(id: ^campaign.id) |> repo().update_all(set: [contact_tag: tag])
        end
      end
    )

    alter table(:campaigns) do
      remove :contact_tag, :string
    end
  end
end
