defmodule MaydayWeb.ContactsLive do
  use MaydayWeb, :live_view

  alias Mayday.Contacts

  @impl true
  def mount(_, _, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Contacts")
     |> assign_contacts()
     |> allow_upload(:contacts_import,
       accept: [".csv"],
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def handle_event("validate", _, socket) do
    # Required for allow_upload/3
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.dashboard_path(@socket, :index)} />

      <div class="flex items-center justify-between">
        <h2 class="text-3xl font-bold"><%= @page_title %></h2>

        <div class="flex flex-col items-end space-y-6 sm:flex-row sm:items-center sm:space-x-6 sm:space-y-0">
          <.link navigate={Routes.contacts_path(@socket, :new)} class="flex items-center space-x-2 text-red-500">
            <I.plus_circle class="h-5 w-5" />
            <span class="underline">Create New Contact</span>
          </.link>

          <.link href={Routes.file_path(@socket, :download_contacts)} class="flex items-center text-red-500 underline">
            <I.document_arrow_down class="mr-2 h-5 w-5" /> Download CSV
          </.link>

          <form phx-change="validate" {tid(:csv_upload)}>
            <label class="Btn Btn--secondary !px-5 flex items-center cursor-pointer">
              <%= live_file_input(@uploads.contacts_import, class: "hidden") %>
              <I.arrow_up_tray class="mr-2 h-5 w-5" />
              <span>Import CSV</span>
            </label>
          </form>
        </div>
      </div>

      <table class="w-full">
        <thead class="border-b border-gray-400 text-left">
          <tr class="Table-row">
            <th class="Table-cell">Last Name</th>
            <th class="Table-cell">First Name</th>
            <th class="Table-cell">Phone Number</th>
            <th class="Table-cell">Tags</th>
            <th class="w-2"></th>
          </tr>
        </thead>
        <tbody>
          <%= for contact <- @contacts do %>
            <tr class="Table-row">
              <td class="Table-cell"><%= contact.last_name %></td>
              <td class="Table-cell"><%= contact.first_name %></td>
              <td class="Table-cell"><%= contact.phone_number %></td>
              <td class="Table-cell">
                <div class="flex gap-1">
                  <%= for tag <- contact.tags do %>
                    <div class="rounded bg-gray-200 px-1 text-sm"><%= tag %></div>
                  <% end %>
                </div>
              </td>
              <td class="Table-cell flex sm:justify-end">
                <.link navigate={Routes.contacts_path(@socket, :edit, contact)} class="text-red-500">
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

  defp handle_progress(:contacts_import, entry, socket) do
    if entry.done? do
      [result] =
        consume_uploaded_entries(socket, :contacts_import, fn %{path: path}, _entry ->
          path
          |> File.stream!()
          |> NimbleCSV.RFC4180.parse_stream()
          |> Enum.reduce(0, fn
            [last_name, first_name, phone_number, tags], acc ->
              case Contacts.create_contact(%{
                     last_name: last_name,
                     first_name: first_name,
                     phone_number: phone_number,
                     tags_input: tags
                   }) do
                {:ok, _} -> acc + 1
                _ -> acc
              end

            _, acc ->
              acc
          end)
          |> then(&{:ok, &1})
        end)

      {:noreply,
       socket |> assign_contacts() |> put_flash(:info, "Imported #{result} new contacts")}
    else
      {:noreply, socket}
    end
  end

  defp assign_contacts(socket) do
    assign(socket, :contacts, Contacts.list_contacts())
  end
end
