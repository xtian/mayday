defmodule Mayday.Contacts do
  import Ecto.Query

  alias Mayday.{Campaigns, Conversations, Conversations.Conversation, Repo}
  alias Mayday.Contacts.{Contact, OptOut}

  def all_matching_filters(filters \\ []) do
    conditions =
      Enum.reduce(filters, false, fn
        %{direction: :include, tag: tag}, conditions ->
          dynamic([c], fragment("? @> ARRAY[?]", c.tags, ^tag) or ^conditions)

        %{direction: :exclude, tag: tag}, false ->
          dynamic([c], not fragment("? @> ARRAY[?]", c.tags, ^tag))

        %{direction: :exclude, tag: tag}, conditions ->
          dynamic([c], not fragment("? @> ARRAY[?]", c.tags, ^tag) and ^conditions)
      end)

    if conditions do
      where(Contact, ^conditions)
    else
      Contact
    end
    # credo:disable-for-next-line Credo.Check.Refactor.PipeChainStart
    |> order_by(asc_nulls_last: :last_name, asc: :first_name)
    |> Repo.all()
  end

  def contact_matches_filters?(contact, filters) do
    Enum.reduce_while(filters, true, fn
      _, false -> {:halt, false}
      %{direction: :include, tag: tag}, matches? -> {:cont, tag in contact.tags and matches?}
      %{direction: :exclude, tag: tag}, matches? -> {:cont, tag not in contact.tags and matches?}
    end)
  end

  def change_contact(contact \\ nil, attrs) do
    Contact.changeset(contact || %Contact{}, attrs)
  end

  def create_contact(attrs) do
    changeset = Contact.changeset(%Contact{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.run(:check_opt_out, fn repo, _ ->
      case Ecto.Changeset.fetch_field(changeset, :phone_number) do
        {_, phone_number} ->
          if phone_number |> hash_phone_number() |> then(&repo.get(OptOut, &1)) do
            {:error, nil}
          else
            {:ok, nil}
          end

        _ ->
          {:ok, nil}
      end
    end)
    |> Ecto.Multi.insert(:contact, changeset)
    |> Ecto.Multi.insert_all(:conversations, Conversation, fn %{contact: contact} ->
      Campaigns.active_campaigns()
      |> Enum.filter(&contact_matches_filters?(contact, &1.tag_filters))
      |> Enum.flat_map(&Conversations.conversations_params(&1, [contact]))
    end)
    |> Repo.transaction()
    |> then(fn
      {:ok, %{contact: contact}} -> {:ok, contact}
      {:error, :contact, changeset, _} -> {:error, changeset}
      {:error, :check_opt_out, _, _} -> {:error, :opted_out}
    end)
  end

  def delete_contact(id) do
    with {:ok, _} <- Repo.delete(%Contact{id: id}), do: :ok
  end

  def get_contact!(id) do
    Repo.get!(Contact, id)
  end

  def fetch_contact_by_phone(phone_number) do
    case Repo.get_by(Contact, phone_number: phone_number) do
      nil -> {:error, :not_found}
      contact -> {:ok, contact}
    end
  end

  def list_contacts do
    Contact |> order_by(asc_nulls_last: :last_name, asc: :first_name) |> Repo.all()
  end

  def opt_out_contact(contact) do
    hash = hash_phone_number(contact.phone_number)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:opt_out, OptOut.changeset(%OptOut{}, %{hash: hash}))
    |> Ecto.Multi.delete(:contact, contact)
    |> Repo.transaction()
    |> then(fn
      {:ok, _} -> :ok
      error -> error
    end)
  end

  def remove_opt_out_for_number!(phone_number) do
    hash = hash_phone_number(phone_number)
    with {:ok, _} <- Repo.delete!(%OptOut{hash: hash}), do: :ok
  end

  def save_contact(nil, attrs), do: create_contact(attrs)
  def save_contact(contact, attrs), do: contact |> change_contact(attrs) |> Repo.update()

  defp hash_phone_number(string) do
    string |> then(&:crypto.hash(:sha256, &1)) |> Base.encode64()
  end
end
