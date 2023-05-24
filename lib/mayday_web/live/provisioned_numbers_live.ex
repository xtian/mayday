defmodule MaydayWeb.ProvisionedNumbersLive do
  use MaydayWeb, :live_view

  alias Mayday.Campaigns

  @impl true
  def mount(_, _, socket) do
    {:ok, socket |> assign_numbers() |> assign(:page_title, "Outgoing Numbers")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.dashboard_path(@socket, :index)} />

      <div class="flex items-center justify-between">
        <h2 class="text-3xl font-bold"><%= @page_title %></h2>

        <.link navigate={Routes.provisioned_numbers_path(@socket, :new)} class="flex items-center space-x-2 text-red-500">
          <I.plus_circle class="h-5 w-5" />
          <span class="underline">Add Outgoing Number</span>
        </.link>
      </div>

      <table class="w-full">
        <thead class="border-b border-gray-400 text-left">
          <tr class="Table-row">
            <th class="Table-cell">Label</th>
            <th class="Table-cell">Phone Number</th>
            <th class="w-2"></th>
          </tr>
        </thead>
        <tbody>
          <%= for number <- @numbers do %>
            <tr class="Table-row">
              <td class="Table-cell"><%= number.label %></td>
              <td class="Table-cell"><%= number.phone_number %></td>
              <td class="Table-cell flex sm:justify-end">
                <.link navigate={Routes.provisioned_numbers_path(@socket, :edit, number.phone_number)} class="text-red-500">
                  <I.pencil class="h-5 w-5" />
                </.link>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </.wrapper>
    """
  end

  defp assign_numbers(socket) do
    assign(socket, :numbers, Campaigns.provisioned_numbers())
  end
end
