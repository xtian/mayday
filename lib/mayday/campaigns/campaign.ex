defmodule Mayday.Campaigns.Campaign do
  use Mayday, :schema

  alias Mayday.{Campaigns, Conversations.Conversation}

  schema "campaigns" do
    field :completed_at, :utc_datetime
    field :name, :string
    field :started_at, :utc_datetime
    field :tag_filters_input, :string, virtual: true

    belongs_to :provisioned_number, Campaigns.ProvisionedNumber,
      foreign_key: :phone_number,
      references: :phone_number,
      type: :binary

    embeds_many :script_messages, Campaigns.ScriptMessage, on_replace: :delete
    embeds_many :tag_filters, Campaigns.TagFilter, on_replace: :delete

    has_many :conversations, Conversation

    timestamps()
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:name, :phone_number, :tag_filters_input])
    |> cast_embed(:script_messages, required: true)
    |> cast_embed(:tag_filters)
    |> validate_required([:name, :phone_number])
    |> then(fn changeset ->
      if filters_input = get_change(changeset, :tag_filters_input) do
        filters_input
        |> String.split(~s/\s/, trim: true)
        |> Enum.uniq()
        |> Enum.flat_map(fn
          "-" <> tag -> [%{tag: tag, direction: :exclude}]
          tag -> [%{tag: tag, direction: :include}]
        end)
        |> then(&put_change(changeset, :tag_filters, &1))
      else
        changeset
      end
    end)
    |> foreign_key_constraint(:phone_number)
  end

  def completed_changeset(schema) do
    change(schema, completed_at: DateTime.truncate(DateTime.utc_now(), :second))
  end

  def started_changeset(schema) do
    change(schema, started_at: DateTime.truncate(DateTime.utc_now(), :second))
  end
end
