defmodule Mayday.Campaigns.ScriptMessage do
  use Mayday, :schema

  alias Mayday.Campaigns.SurveyOption

  embedded_schema do
    field :message_template, :string
    field :report_label, :string

    embeds_many :survey_options, SurveyOption, on_replace: :delete
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:message_template, :report_label])
    |> cast_embed(:survey_options)
    |> update_change(:message_template, &String.trim/1)
    |> validate_change(:message_template, fn field, template ->
      case Solid.parse(template) do
        {:ok, _} -> []
        _ -> [{field, "Invalid message"}]
      end
    end)
    |> validate_required([:message_template])
  end
end
