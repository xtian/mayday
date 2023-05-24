defmodule Mayday.Campaigns do
  import Ecto.Query
  import EctoNestedChangeset

  alias Mayday.{Contacts, Conversations, Conversations.Conversation, Repo}

  alias Mayday.Campaigns.{
    Campaign,
    ProvisionedNumber,
    ScriptMessage,
    SurveyOption
  }

  def active_campaigns do
    Campaign
    |> where([c], not is_nil(c.started_at) and is_nil(c.completed_at))
    |> preload(:conversations)
    |> Repo.all()
  end

  def add_script_message(changeset) do
    append_at(changeset, [:script_messages], %ScriptMessage{})
  end

  def add_survey_option(changeset, index) do
    path = [:script_messages, index, :survey_options]

    if changeset |> get_at(path) |> Enum.count() == 0 do
      changeset
      |> append_at(path, %SurveyOption{value: "Yes"})
      |> append_at(path, %SurveyOption{value: "No"})
    else
      append_at(changeset, path, %SurveyOption{})
    end
  end

  def campaigns do
    Campaign
    |> order_by(desc_nulls_first: :completed_at, desc_nulls_last: :started_at, desc: :inserted_at)
    |> preload(:provisioned_number)
    |> Repo.all()
  end

  def change_campaign(campaign \\ nil, attrs) do
    Campaign.changeset(campaign || %Campaign{}, attrs)
  end

  def change_provisioned_number(number \\ nil, attrs) do
    ProvisionedNumber.changeset(number || %ProvisionedNumber{}, attrs)
  end

  def complete_campaign!(campaign) do
    campaign |> Campaign.completed_changeset() |> Repo.update!()
  end

  def save_provisioned_number(number, attrs) do
    number |> change_provisioned_number(attrs) |> Repo.insert_or_update()
  end

  def delete_campaign(id) do
    with {:ok, _} <- Repo.delete(%Campaign{id: id}), do: :ok
  end

  def delete_provisioned_number(id) do
    with {:ok, _} <- Repo.delete(%ProvisionedNumber{phone_number: id}), do: :ok
  end

  def fetch_active_campaign(phone_number) do
    Campaign
    |> where(phone_number: ^phone_number)
    |> where([c], not is_nil(c.started_at) and is_nil(c.completed_at))
    |> Repo.all()
    |> case do
      [] -> {:error, :not_found}
      [campaign] -> {:ok, campaign}
    end
  end

  def get_campaign!(id) do
    Campaign |> preload([:provisioned_number, conversations: [:contact]]) |> Repo.get!(id)
  end

  def get_provisioned_number!(id) do
    Repo.get!(ProvisionedNumber, id)
  end

  def provisioned_numbers do
    Repo.all(ProvisionedNumber)
  end

  def remove_script_message(changeset, index) do
    delete_at(changeset, [:script_messages, index])
  end

  def remove_survey_option(changeset, script_index, survey_index) do
    delete_at(changeset, [:script_messages, script_index, :survey_options, survey_index])
  end

  def render_message_template(string, data) do
    with true <- is_binary(string) and String.trim(string) != "",
         {:ok, template} <- Solid.parse(string) do
      Solid.render(template, data)
    else
      false -> {:error, :empty}
      error -> error
    end
  end

  def save_campaign(campaign, attrs) do
    campaign |> change_campaign(attrs) |> Repo.insert_or_update()
  end

  def start_campaign(campaign) do
    query =
      Campaign
      |> where(phone_number: ^campaign.phone_number)
      |> where([c], c.id != ^campaign.id and is_nil(c.completed_at))

    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:campaigns, query, set: [completed_at: NaiveDateTime.utc_now()])
    |> Ecto.Multi.update(:campaign, Campaign.started_changeset(campaign))
    |> Ecto.Multi.insert_all(:conversations, Conversation, fn %{campaign: campaign} ->
      Conversations.conversations_params(
        campaign,
        Contacts.all_matching_filters(campaign.tag_filters)
      )
    end)
    |> Repo.transaction()
    |> then(fn {:ok, %{campaign: campaign}} -> {:ok, campaign} end)
  end
end
