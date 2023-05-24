defmodule Mayday.Campaigns.TagFilter do
  use Mayday, :schema

  @directions [:exclude, :include]

  embedded_schema do
    field :direction, Ecto.Enum, values: @directions
    field :tag, :string
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:direction, :tag])
    |> validate_required([:direction, :tag])
  end
end
