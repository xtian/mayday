defmodule MaydayWeb.ProvisionedNumberFormLive do
  use MaydayWeb, :live_view

  alias Mayday.Campaigns

  @impl true
  def mount(params, _, socket) do
    params
    |> case do
      %{"id" => id} ->
        number = Campaigns.get_provisioned_number!(id)

        [
          number: number,
          changeset: Campaigns.change_provisioned_number(number, %{}),
          page_title: "Update Outgoing Number"
        ]

      _ ->
        [
          number: nil,
          changeset: Campaigns.change_provisioned_number(%{}),
          page_title: "Add Outgoing Number"
        ]
    end
    |> then(&{:ok, assign(socket, &1)})
  end

  @impl true
  def handle_event("save", %{"provisioned_number" => params}, %{assigns: assigns} = socket) do
    case Campaigns.save_provisioned_number(assigns.number, params) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Outgoing number saved")
          |> push_redirect(to: Routes.provisioned_numbers_path(socket, :index))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"provisioned_number" => params}, %{assigns: assigns} = socket) do
    {:noreply,
     assign(socket, :changeset, Campaigns.change_provisioned_number(assigns.number, params))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.provisioned_numbers_path(@socket, :index)} />

      <div class="flex max-w-lg justify-between">
        <h2 class="text-3xl font-bold"><%= @page_title %></h2>
      </div>

      <.form
        :let={f}
        for={@changeset}
        phx-change="validate"
        phx-submit="save"
        class="flex flex-col"
        {tid(:provisioned_number_form)}
      >
        <div class="flex max-w-lg flex-col space-y-4">
          <label>
            <div class="mb-2">Label</div>
            <%= telephone_input(f, :label, required: true, class: "Input") %>
          </label>
          <%= error_tag(f, :label) %>

          <%= unless @number do %>
            <label>
              <div class="mb-2">Phone Number</div>
              <%= telephone_input(f, :phone_number, required: true, class: "Input") %>
            </label>
            <%= error_tag(f, :phone_number) %>
          <% end %>

          <button class="!mt-8 self-end Btn Btn--primary">Save</button>
        </div>
      </.form>
    </.wrapper>
    """
  end
end
