defmodule Mayday.Contacts.Contact do
  use Mayday, :schema

  schema "contacts" do
    field :first_name, :string
    field :last_name, :string
    field :phone_number, :string
    field :tags, {:array, :string}, default: []
    field :tags_input, :string, virtual: true

    timestamps()
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:first_name, :last_name, :phone_number, :tags_input])
    |> validate_required([:first_name, :phone_number])
    |> validate_format(:phone_number, ~r/^[0-9]{10}$/,
      message: "must be 10 digits with no separators"
    )
    |> validate_format(:tags_input, ~r/^[\w\s-]*$/,
      message: "can only contain letters, numbers, dashes, and underscores"
    )
    |> then(fn changeset ->
      if tags_input = get_change(changeset, :tags_input) do
        list = tags_input |> String.split(~s/\s/, trim: true) |> Enum.uniq()
        put_change(changeset, :tags, list)
      else
        changeset
      end
    end)
    |> unique_constraint(:phone_number)
  end
end
