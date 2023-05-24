defmodule Mayday.Contacts.OptOut do
  use Mayday, :schema

  @primary_key {:hash, :string, autogenerate: false}

  schema "opt_outs" do
    timestamps(updated_at: false)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:hash])
    |> validate_required([:hash])
  end
end
