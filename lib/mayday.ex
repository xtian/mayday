defmodule Mayday do
  defmacro __using__(:schema) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @type t :: %__MODULE__{}
    end
  end

  def broadcast(topic, payload) do
    Phoenix.PubSub.broadcast(Mayday.PubSub, topic, payload)
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Mayday.PubSub, topic)
  end
end
