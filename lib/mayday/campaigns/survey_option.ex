defmodule Mayday.Campaigns.SurveyOption do
  use Mayday, :schema

  embedded_schema do
    field :value, :string
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:value])
    |> validate_required([:value])
  end
end
