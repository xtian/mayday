defmodule Mayday.Actions do
  import Ecto.Query

  alias __MODULE__.{Action, ActionNotifier}
  alias Mayday.Repo

  def change_action(action \\ %Action{}, attrs) do
    Action.changeset(action, attrs)
  end

  def create_action(action \\ %Action{}, attrs) do
    with {:ok, action} = result <- action |> Action.changeset(attrs) |> Repo.insert() do
      ActionNotifier.deliver_action_confirmation(action)
      result
    end
  end

  def list_actions do
    Action |> order_by(desc: :inserted_at) |> Repo.all()
  end
end
