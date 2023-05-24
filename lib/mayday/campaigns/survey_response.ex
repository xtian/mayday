defmodule Mayday.Campaigns.SurveyResponse do
  use Mayday, :schema

  embedded_schema do
    field :value, :string
  end

  def changeset(schema, attrs) do
    cast(schema, attrs, [:value])
  end
end
