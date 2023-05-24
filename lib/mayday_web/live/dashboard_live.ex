defmodule MaydayWeb.DashboardLive do
  use MaydayWeb, :live_view

  alias Mayday.{Campaigns, Conversations}

  @impl true
  def mount(_, _, %{assigns: assigns} = socket) do
    if connected?(socket) do
      Mayday.subscribe("users:#{assigns.current_user.id}:conversations")
    end

    {:ok, assign_campaigns(socket)}
  end

  @impl true
  def handle_info({:new_message, _}, socket) do
    {:noreply, assign_campaigns(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.tools role={@current_user.role} socket={@socket} />

      <section class="space-y-4">
        <h2 class="text-3xl font-bold">Active Campaigns</h2>

        <%= if Enum.empty?(@active_campaigns) do %>
          <p>There are no active campaigns right now!</p>
        <% else %>
          <%= for {campaign, unread_count, unstarted_count, own_count} <- @active_campaigns do %>
            <.link navigate={Routes.conversations_path(@socket, :index, campaign)} class="block">
              <article class="flex max-w-xl flex-col rounded-lg border border-gray-400 px-6 py-4 shadow">
                <div class="mb-4 flex justify-between">
                  <h3 class="mr-2 break-all text-lg font-bold"><%= campaign.name %></h3>

                  <div class="flex items-center text-red-500">
                    <span class="mr-1 underline">Start Texting</span>
                    <I.arrow_right class="h-4 w-4 shrink-0" />
                  </div>
                </div>

                <dl>
                  <div class="flex items-center justify-between">
                    <dt class="mr-2 font-bold">Your conversations:</dt>
                    <dd><%= unread_count %> unread / <%= own_count %></dd>
                  </div>
                  <div class="flex items-center justify-between">
                    <dt class="mr-2 font-bold">Available conversations:</dt>
                    <dd><%= unstarted_count %></dd>
                  </div>
                </dl>
              </article>
            </.link>
          <% end %>
        <% end %>
      </section>
    </.wrapper>
    """
  end

  defp assign_campaigns(%{assigns: %{current_user: %{id: user_id}}} = socket) do
    {active_campaigns, unread_count} =
      Enum.map_reduce(Campaigns.active_campaigns(), 0, fn campaign, acc ->
        own_conversations = Enum.filter(campaign.conversations, &(&1.user_id == user_id))
        unread_count = Enum.count(own_conversations, &Conversations.unread?/1)

        {{
           campaign,
           unread_count,
           Enum.count(campaign.conversations, &(&1.user_id == nil)),
           Enum.count(own_conversations)
         }, acc + unread_count}
      end)

    unread_count = if unread_count > 0, do: "(#{unread_count}) ", else: ""

    assign(socket, active_campaigns: active_campaigns, page_title: "#{unread_count}Dashboard")
  end

  defp tools(assigns) when assigns.role in [:admin, :owner] do
    ~H"""
    <section>
      <h2 class="mb-2 text-lg font-bold">Admin Tools</h2>

      <ul class="text-red-500 underline">
        <li>
          <.link navigate={Routes.campaigns_path(@socket, :index)}>Campaigns</.link>
        </li>
        <li>
          <.link navigate={Routes.contacts_path(@socket, :index)}>Contacts</.link>
        </li>
        <li>
          <.link navigate={Routes.provisioned_numbers_path(@socket, :index)}>Outgoing Numbers</.link>
        </li>
        <li>
          <.link navigate={Routes.users_path(@socket, :index)}>Users</.link>
        </li>
      </ul>
    </section>
    """
  end

  defp tools(%{role: :manager} = assigns) do
    ~H"""
    <section>
      <h2 class="mb-2 text-lg font-bold">Manager Tools</h2>

      <ul class="text-red-500 underline">
        <li>
          <.link navigate={Routes.campaigns_path(@socket, :index)}>Campaigns</.link>
        </li>
      </ul>
    </section>
    """
  end

  defp tools(assigns) do
    ~H""
  end
end
