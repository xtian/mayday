defmodule MaydayWeb.ConversationsLive do
  use MaydayWeb, :live_view

  alias Mayday.{Campaigns, Conversations}

  @impl true
  def mount(%{"campaign_id" => campaign_id}, _, %{assigns: assigns} = socket) do
    if connected?(socket), do: Mayday.subscribe("users:#{assigns.current_user.id}:conversations")

    campaign = Campaigns.get_campaign!(campaign_id)
    socket = socket |> assign(:campaign, campaign) |> assign_conversations()

    {:ok, socket}
  end

  @impl true
  def handle_event("next-conversation", _, %{assigns: assigns} = socket) do
    socket =
      case Conversations.next_conversation(assigns.campaign.id, assigns.current_user.id) do
        {:ok, nil} ->
          put_flash(socket, :info, "No new conversations available")

        {:ok, conversation} ->
          path = Routes.conversations_path(socket, :show, assigns.campaign, conversation)
          push_redirect(socket, to: path)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_message, _}, socket) do
    {:noreply, assign_conversations(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.dashboard_path(@socket, :index)} />

      <div class="flex items-center justify-between">
        <h2 class="text-3xl font-bold"><%= @page_title %></h2>

        <button class="Btn Btn--primary" phx-click="next-conversation" {tid(:next_conversation)}>
          Start New Conversation
        </button>
      </div>

      <table class="w-full">
        <thead class="border-b border-gray-400 text-left">
          <tr class="Table-row">
            <th class="w-4"></th>
            <th class="w-8"></th>
            <th class="Table-cell">Contact Name</th>

            <%= for script_message <- @campaign.script_messages do %>
              <th class="py-1 sm:p-2">
                <%= script_message.report_label %>
              </th>
            <% end %>
          </tr>
        </thead>
        <tbody {tid(:conversations)}>
          <%= for {conversation, index} <- Enum.with_index(@conversations, 1) do %>
            <tr class="flex flex-col p-2 even:bg-gray-200 sm:table-row sm:p-0">
              <td>
                <div class={"#{if Conversations.unread?(conversation), do: "bg-red-500"} h-2 w-2 rounded-full"}></div>
              </td>
              <td><%= index %>.</td>

              <td class="Table-cell">
                <.link
                  navigate={Routes.conversations_path(@socket, :show, @campaign, conversation)}
                  class="text-red-500 underline"
                >
                  <%= full_name(conversation.contact) %>
                </.link>
              </td>

              <%= for survey_response <- conversation.survey_responses do %>
                <td class="py-1 sm:p-2">
                  <%= if survey_response.value do %>
                    <I.check class="h-5 w-5" />
                  <% end %>
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </.wrapper>
    """
  end

  defp assign_conversations(%{assigns: assigns} = socket) do
    conversations = Conversations.list_conversations(assigns.campaign.id, assigns.current_user.id)
    unread_count = Enum.count(conversations, &Conversations.unread?/1)
    unread_count = if unread_count > 0, do: "(#{unread_count}) ", else: ""

    assign(socket, conversations: conversations, page_title: "#{unread_count}Your Conversations")
  end
end
