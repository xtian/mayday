defmodule MaydayWeb.CampaignsLive do
  use MaydayWeb, :live_view

  alias Mayday.Campaigns

  @impl true
  def mount(_, _, socket) do
    {:ok, assign(socket, campaigns: Campaigns.campaigns(), page_title: "Campaigns")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.dashboard_path(@socket, :index)} />

      <div class="flex items-center justify-between">
        <h2 class="text-3xl font-bold"><%= @page_title %></h2>
        <.link navigate={Routes.campaigns_path(@socket, :new)} class="flex items-center space-x-2 text-red-500">
          <I.plus_circle class="h-5 w-5" />
          <span class="underline">Create New Campaign</span>
        </.link>
      </div>

      <table class="w-full">
        <thead class="border-b border-gray-400 text-left">
          <tr class="Table-row">
            <th class="Table-cell">Name</th>
            <th class="Table-cell">Outgoing Number</th>
            <th class="Table-cell">Created</th>
            <th class="Table-cell">Started</th>
            <th class="Table-cell">Completed</th>
          </tr>
        </thead>
        <tbody>
          <%= for campaign <- @campaigns do %>
            <tr class="Table-row">
              <td class="Table-cell">
                <.link navigate={Routes.campaigns_path(@socket, :show, campaign)} class="text-red-500 underline">
                  <%= campaign.name %>
                </.link>
              </td>
              <td class="Table-cell"><%= campaign.provisioned_number.label %></td>
              <td class="Table-cell"><%= format_datetime(campaign.inserted_at) %></td>
              <td class="Table-cell"><%= format_datetime(campaign.started_at) %></td>
              <td class="Table-cell"><%= format_datetime(campaign.completed_at) %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </.wrapper>
    """
  end
end
