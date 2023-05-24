defmodule Mayday.Campaigns.ProvisionedNumber do
  use Mayday, :schema

  @primary_key {:phone_number, :string, autogenerate: false}

  schema "provisioned_numbers" do
    field :label, :string
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:label, :phone_number])
    |> validate_required([:label, :phone_number])
    |> validate_format(:phone_number, ~r/^[0-9]{10}$/,
      message: "must be 10 digits with no separators"
    )
  end
end
