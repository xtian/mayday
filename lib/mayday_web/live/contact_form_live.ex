defmodule MaydayWeb.ContactFormLive do
  use MaydayWeb, :live_view

  import Ecto.Changeset, only: [get_field: 2]

  alias Mayday.Contacts

  @impl true
  def mount(params, _, socket) do
    params
    |> case do
      %{"id" => id} ->
        contact = Contacts.get_contact!(id)

        [
          contact: contact,
          changeset: Contacts.change_contact(contact, %{}),
          page_title: "Update Contact"
        ]

      _ ->
        [
          contact: nil,
          changeset: Contacts.change_contact(%{}),
          page_title: "Create New Contact"
        ]
    end
    |> then(&{:ok, assign(socket, &1)})
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    socket =
      case id |> String.to_integer() |> Contacts.delete_contact() do
        :ok ->
          socket
          |> put_flash(:info, "Contact deleted")
          |> push_redirect(to: Routes.contacts_path(socket, :index))

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("save", %{"contact" => params}, %{assigns: assigns} = socket) do
    case Contacts.save_contact(assigns.contact, params) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Contact saved")
          |> push_redirect(to: Routes.contacts_path(socket, :index))

        {:noreply, socket}

      {:error, :opted_out} ->
        {:noreply,
         put_flash(socket, :error, "Phone number has been opted-out of receiving messages")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"contact" => params}, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, :changeset, Contacts.change_contact(assigns.contact, params))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.contacts_path(@socket, :index)} />

      <div class="flex max-w-lg justify-between">
        <h2 class="text-3xl font-bold"><%= @page_title %></h2>

        <%= if @contact do %>
          <button
            type="button"
            class="flex items-center space-x-2 text-red-500"
            data-confirm="Are you sure you want to delete this contact? This cannot be undone."
            phx-click="delete"
            phx-value-id={@contact.id}
            {tid(:delete_contact)}
          >
            <I.trash class="h-5 w-5" />
            <span>Delete</span>
          </button>
        <% end %>
      </div>

      <.form :let={f} for={@changeset} phx-change="validate" phx-submit="save" class="flex flex-col" {tid(:contact_form)}>
        <div class="flex max-w-lg flex-col space-y-4">
          <div class="flex gap-4">
            <div class="grow">
              <label>
                <div class="mb-2">First Name</div>
                <%= text_input(f, :first_name, required: true, class: "Input") %>
              </label>
              <%= error_tag(f, :first_name) %>
            </div>

            <div class="grow">
              <label>
                <div class="mb-2">Last Name</div>
                <%= text_input(f, :last_name, class: "Input") %>
              </label>
              <%= error_tag(f, :last_name) %>
            </div>
          </div>

          <label>
            <div class="mb-2">Phone Number</div>
            <%= telephone_input(f, :phone_number, required: true, class: "Input") %>
          </label>
          <%= error_tag(f, :phone_number) %>

          <label>
            <div class="mb-2">Tags (space-separated)</div>
            <%= text_input(f, :tags_input,
              class: "Input",
              value: f.source |> get_field(:tags) |> Enum.join(" "),
              autocomplete: false,
              autocorrect: false,
              spellcheck: false
            ) %>
          </label>
          <%= error_tag(f, :tags_input) %>

          <button class="!mt-8 self-end Btn Btn--primary">Save</button>
        </div>
      </.form>
    </.wrapper>
    """
  end
end
