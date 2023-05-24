defmodule MaydayWeb.CampaignLive do
  use MaydayWeb, :live_view

  alias Mayday.Campaigns

  @impl true
  def mount(%{"id" => id}, _, socket) do
    campaign = Campaigns.get_campaign!(id)
    {:ok, assign(socket, campaign: campaign, page_title: campaign.name)}
  end

  @impl true
  def handle_event("complete", _, %{assigns: %{campaign: campaign}} = socket) do
    {:noreply, assign(socket, :campaign, Campaigns.complete_campaign!(campaign))}
  end

  def handle_event("start", _, %{assigns: %{campaign: campaign}} = socket) do
    {:ok, campaign} = Campaigns.start_campaign(campaign)
    {:noreply, assign(socket, :campaign, campaign)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.campaigns_path(@socket, :index)} />

      <div class="flex items-center justify-between">
        <h2 class="break-all text-3xl font-bold"><%= @campaign.name %></h2>

        <div class="flex space-x-4">
          <%= unless @campaign.started_at do %>
            <.link navigate={Routes.campaigns_path(@socket, :edit, @campaign)} class="p-2 text-red-500">
              Edit Campaign
            </.link>

            <button
              class="Btn Btn--primary"
              phx-click="start"
              data-confirm={
                "Start this campaign? This will complete any active campaign using the outgoing number #{@campaign.phone_number}."
              }
            >
              Start Campaign
            </button>
          <% end %>

          <%= if @campaign.started_at && !@campaign.completed_at do %>
            <button
              class="Btn Btn--primary"
              phx-click="complete"
              data-confirm="Complete this campaign? No more messages will be able to be sent."
            >
              Complete Campaign
            </button>
          <% end %>
        </div>
      </div>

      <section>
        <dl>
          <div class="flex w-64 items-center justify-between">
            <dt class="mr-2 font-bold">Outgoing Number:</dt>
            <dd><%= @campaign.provisioned_number.label %></dd>
          </div>

          <div class="flex w-64 items-center justify-between">
            <dt class="mr-2 font-bold">Tag Filters:</dt>
            <dd class="flex space-x-2">
              <%= for filter <- @campaign.tag_filters do %>
                <.tag_filter direction={filter.direction} tag={filter.tag} />
              <% end %>
            </dd>
          </div>

          <div class="flex w-64 justify-between">
            <dt class="mr-2 font-bold">Created:</dt>
            <dd><%= format_datetime(@campaign.inserted_at) %></dd>
          </div>

          <div class="flex w-64 justify-between">
            <dt class="mr-2 font-bold">Updated:</dt>
            <dd><%= format_datetime(@campaign.updated_at) %></dd>
          </div>

          <div class="flex w-64 justify-between">
            <dt class="mr-2 font-bold">Started:</dt>
            <dd><%= format_datetime(@campaign.started_at) %></dd>
          </div>

          <div class="flex w-64 justify-between">
            <dt class="mr-2 font-bold">Completed:</dt>
            <dd><%= format_datetime(@campaign.completed_at) %></dd>
          </div>
        </dl>
      </section>

      <section class="space-y-6">
        <div class="flex items-center justify-between">
          <h3 class="text-xl font-bold">Responses</h3>

          <.link
            href={Routes.file_path(@socket, :download_responses, @campaign)}
            class="flex items-center text-red-500 underline"
          >
            <I.document_arrow_down class="mr-2 h-5 w-5" /> Download CSV
          </.link>
        </div>

        <table class="w-full">
          <thead class="border-b border-gray-400 text-left">
            <tr class="flex flex-col p-2 sm:table-row sm:p-0">
              <th class="py-1 sm:p-2">Last Name</th>
              <th class="py-1 sm:p-2">First Name</th>

              <%= for script_message <- @campaign.script_messages do %>
                <th class="py-1 sm:p-2">
                  <%= script_message.report_label %>
                </th>
              <% end %>

              <th class="py-1 sm:p-2">Notes</th>
            </tr>
          </thead>
          <tbody>
            <%= for conversation <- @campaign.conversations do %>
              <tr class="flex flex-col p-2 even:bg-gray-200 sm:table-row sm:p-0">
                <td class="py-1 sm:p-2"><%= conversation.contact.last_name %></td>
                <td class="py-1 sm:p-2"><%= conversation.contact.first_name %></td>

                <%= for survey_response <- conversation.survey_responses do %>
                  <td class="py-1 sm:p-2"><%= survey_response.value %></td>
                <% end %>

                <td class="max-w-xs truncate py-1 sm:p-2"><%= conversation.notes %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </section>
    </.wrapper>
    """
  end
end
