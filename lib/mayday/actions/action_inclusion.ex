defmodule Mayday.Actions.ActionInclusion do
  use Mayday, :schema

  alias Mayday.Actions

  schema "action_inclusions" do
    belongs_to :action, Actions.Action
    belongs_to :action_email, Actions.ActionEmail
  end
end
