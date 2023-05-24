defmodule Mayday.Actions.Action do
  use Mayday, :schema

  @states [:colorado, :national, :wyoming]

  schema "actions" do
    field :address, :string
    field :approved_at, :utc_datetime
    field :comment, :string
    field :cost_to_attend, :decimal
    field :description, :string
    field :sponsor, :string
    field :state, Ecto.Enum, values: @states, default: :colorado
    field :title, :string
    field :url, :string

    field :submitter_email, :string
    field :submitter_name, :string

    field :starts_at, :naive_datetime
    field :ends_at, :time

    timestamps()
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [
      :address,
      :comment,
      :cost_to_attend,
      :description,
      :ends_at,
      :sponsor,
      :starts_at,
      :state,
      :submitter_email,
      :submitter_name,
      :title,
      :url
    ])
    |> validate_required([:description, :starts_at, :submitter_email, :submitter_name, :title])
    |> validate_length(:address, max: 1000)
    |> validate_length(:comment, max: 10_000)
    |> validate_length(:description, max: 10_000)
    |> validate_length(:sponsor, max: 500)
    |> validate_length(:submitter_email, max: 500)
    |> validate_length(:submitter_email, max: 500)
    |> validate_length(:title, max: 500)
    |> validate_length(:url, max: 1000)
    |> validate_number(:cost_to_attend, greater_than: 0)
    |> validate_inclusion(:state, @states)
    |> validate_format(:submitter_email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_change(:starts_at, fn _, starts_at ->
      if NaiveDateTime.compare(NaiveDateTime.utc_now(), starts_at) == :gt do
        [starts_at: "must be after current time"]
      else
        []
      end
    end)
    |> then(fn changeset ->
      starts_at = get_field(changeset, :starts_at)
      ends_at = get_field(changeset, :ends_at)

      with true <- starts_at != nil and ends_at != nil,
           true <- starts_at |> NaiveDateTime.to_time() |> Time.compare(ends_at) != :lt do
        add_error(changeset, :ends_at, "must be after starting time")
      else
        _ -> changeset
      end
    end)
    |> check_constraint(:address,
      name: "location_or_url_must_be_non_null",
      message: "either location or URL is required"
    )
  end
end
