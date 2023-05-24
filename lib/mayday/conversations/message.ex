defmodule Mayday.Conversations.Message do
  use Mayday, :schema

  alias Mayday.{Accounts.User, Contacts.Contact, Conversations.Conversation}

  schema "messages" do
    field :body, :string

    belongs_to :contact, Contact
    belongs_to :conversation, Conversation
    belongs_to :user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:body, :contact_id, :conversation_id, :user_id])
    |> validate_required([:body])
    |> assoc_constraint(:contact)
    |> assoc_constraint(:conversation)
    |> assoc_constraint(:user)
  end
end
