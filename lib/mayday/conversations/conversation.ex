defmodule Mayday.Conversations.Conversation do
  use Mayday, :schema

  alias Mayday.{Accounts.User, Contacts.Contact, Conversations.Message}
  alias Mayday.Campaigns.{Campaign, SurveyResponse}

  schema "conversations" do
    field :notes, :string

    field :completed_at, :utc_datetime
    field :last_message_at, :utc_datetime
    field :last_read_at, :utc_datetime
    field :started_at, :utc_datetime

    belongs_to :campaign, Campaign
    belongs_to :contact, Contact
    belongs_to :user, User

    embeds_many :survey_responses, SurveyResponse, on_replace: :delete

    has_many :messages, Message, preload_order: [asc: :inserted_at]

    timestamps()
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:campaign_id, :contact_id, :notes, :user_id])
    |> cast_embed(:survey_responses, required: true)
    |> assoc_constraint(:campaign)
    |> assoc_constraint(:contact)
    |> assoc_constraint(:user)
  end

  def take_changeset(schema, user_id) do
    change(schema, user_id: user_id)
  end

  def message_received_changeset(schema) do
    change(schema, last_message_at: DateTime.truncate(DateTime.utc_now(), :second))
  end
end
