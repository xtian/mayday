defmodule Mayday.Conversations do
  import Ecto.Query

  alias Mayday.{Campaigns, Campaigns.SurveyResponse, Contacts, HTTPClient, Repo}
  alias Mayday.Conversations.{Conversation, Message}

  require Logger

  def change_conversation(conversation \\ %Conversation{}, attrs) do
    Conversation.changeset(conversation, attrs)
  end

  def change_message(message \\ %Message{}, attrs) do
    Message.changeset(message, attrs)
  end

  def conversations_params(campaign, contacts) do
    survey_responses =
      for _ <- 1..Enum.count(campaign.script_messages) do
        %SurveyResponse{id: Ecto.UUID.generate()}
      end

    for %{id: contact_id} <- contacts do
      %{
        campaign_id: campaign.id,
        contact_id: contact_id,
        survey_responses: survey_responses,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    end
  end

  def create_contact_response(contact_phone, outgoing_phone, body) do
    with {:ok, %{id: campaign_id}} <- Campaigns.fetch_active_campaign(outgoing_phone),
         {:ok, %{id: contact_id}} <- Contacts.fetch_contact_by_phone(contact_phone) do
      conversations =
        Conversation
        |> where(campaign_id: ^campaign_id, contact_id: ^contact_id)
        |> Repo.all()

      with [conversation] <- conversations do
        params = %{body: body, conversation_id: conversation.id, contact_id: contact_id}

        Ecto.Multi.new()
        |> Ecto.Multi.insert(:message, change_message(params))
        |> Ecto.Multi.update(:conversation, Conversation.message_received_changeset(conversation))
        |> Repo.transaction()
        |> then(fn
          {:ok, %{message: message}} ->
            Mayday.broadcast("conversations:#{conversation.id}", {:new_message, message})

            if conversation.user_id do
              Mayday.broadcast(
                "users:#{conversation.user_id}:conversations",
                {:new_message, conversation.id}
              )
            end

          _ ->
            :ok
        end)
      end
    end
  end

  def get_conversation!(conversation_id, user_id) do
    Conversation
    |> preload([:contact, :messages])
    |> Repo.get_by!(id: conversation_id, user_id: user_id)
  end

  def list_conversations(campaign_id, user_id) do
    Conversation
    |> where(campaign_id: ^campaign_id, user_id: ^user_id)
    |> preload(:contact)
    |> Repo.all()
  end

  def next_conversation(campaign_id, user_id) do
    Repo.transaction(fn ->
      conversation =
        Conversation
        |> where(campaign_id: ^campaign_id)
        |> where([c], is_nil(c.user_id))
        |> limit(1)
        |> Repo.all()
        |> List.first()

      if conversation do
        conversation |> Conversation.take_changeset(user_id) |> Repo.update!()
      end
    end)
  end

  def read_conversation(conversation_id) do
    Conversation
    |> where(id: ^conversation_id)
    |> Repo.update_all(set: [last_read_at: DateTime.truncate(DateTime.utc_now(), :second)])
  end

  @http_client Application.compile_env(:mayday, :http_client, HTTPClient)

  def send_message(params, opts) do
    conversation = Keyword.fetch!(opts, :conversation)
    current_user_id = Keyword.fetch!(opts, :current_user_id)

    result =
      params
      |> Map.put("conversation_id", conversation.id)
      |> Map.put("user_id", current_user_id)
      |> change_message()
      |> Repo.insert()

    with {:ok, message} <- result do
      api_key = Application.fetch_env!(:mayday, :telnyx_api_key)
      %{phone_number: from_number} = Keyword.fetch!(opts, :campaign)

      Task.start(fn ->
        "https://api.telnyx.com/v2/messages"
        |> @http_client.post_json(
          [{"authorization", "Bearer #{api_key}"}],
          %{
            from: "+1#{from_number}",
            to: "+1#{conversation.contact.phone_number}",
            text: message.body
          }
        )
        |> maybe_log_error()
      end)
    end

    result
  end

  def unread?(%{last_message_at: %{}, last_read_at: nil}) do
    true
  end

  def unread?(%{last_message_at: %{} = last_message_at, last_read_at: %{} = last_read_at}) do
    DateTime.compare(last_read_at, last_message_at) == :lt
  end

  def unread?(_) do
    false
  end

  def update_conversation(conversation, attrs) do
    conversation |> Conversation.changeset(attrs) |> Repo.update()
  end

  defp maybe_log_error({:ok, %{status: status}}) when status < 300, do: :ok
  defp maybe_log_error({:error, error}), do: Logger.error("Request failed: #{inspect(error)}")

  defp maybe_log_error({:ok, %{status: status, body: body}}) do
    error =
      case Jason.decode(body) do
        {:ok, %{"errors" => [error | _]}} -> error
        {:ok, %{"error" => error}} -> error
        _ -> %{}
      end

    Logger.error("Request failed: #{status} #{error["code"]} #{error["detail"]}")
  end
end
