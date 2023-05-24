defmodule Mayday.Actions.ActionEmail do
  use Mayday, :schema

  alias Mayday.Actions.ActionInclusion

  schema "action_emails" do
    field :scheduled_at, :utc_datetime
    field :sent_at, :utc_datetime

    has_many :action_inclusions, ActionInclusion
    has_many :actions, through: [:action_inclusions, :action]
  end
end
