defmodule MaydayWeb.UsersLive do
  use MaydayWeb, :live_view

  alias Mayday.Accounts

  @empty_users Map.new(Accounts.user_roles(), &{&1, []})

  @impl true
  def mount(_, _, socket) do
    users =
      Accounts.list_users() |> Enum.group_by(& &1.role) |> then(&Map.merge(@empty_users, &1))

    {:ok, socket |> assign(users) |> assign(:page_title, "Users")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.dashboard_path(@socket, :index)} />

      <div class="flex items-center justify-between">
        <h2 class="text-3xl font-bold"><%= @page_title %></h2>

        <.link navigate={Routes.users_path(@socket, :new)} class="flex items-center space-x-2 text-red-500">
          <I.plus_circle class="h-5 w-5" />
          <span class="underline">Create New User</span>
        </.link>
      </div>

      <section {tid(:admins)}>
        <h3 class="mb-4 text-xl font-bold">Administrators</h3>
        <.users_table socket={@socket} users={@admin} />
      </section>

      <section {tid(:managers)}>
        <h3 class="mb-4 text-xl font-bold">Managers</h3>
        <.users_table socket={@socket} users={@manager} />
      </section>

      <section {tid(:texters)}>
        <h3 class="mb-4 text-xl font-bold">Texters</h3>
        <.users_table socket={@socket} users={@texter} />
      </section>

      <section {tid(:deactivated)}>
        <h3 class="mb-4 text-xl font-bold">Deactivated</h3>
        <.users_table socket={@socket} users={@deactivated} />
      </section>
    </.wrapper>
    """
  end

  defp users_table(assigns) do
    ~H"""
    <table class="w-full table-fixed">
      <thead class="border-b border-gray-400 text-left">
        <tr class="Table-row">
          <th class="Table-cell">Last Name</th>
          <th class="Table-cell">First Name</th>
          <th class="Table-cell">Email</th>
          <th class="Table-cell">Created</th>
          <th class="w-2"></th>
        </tr>
      </thead>
      <tbody>
        <%= for user <- @users do %>
          <tr class="Table-row">
            <td class="Table-cell"><%= user.last_name %></td>
            <td class="Table-cell"><%= user.first_name %></td>
            <td class="Table-cell"><%= user.email %></td>
            <td class="Table-cell"><%= format_datetime(user.inserted_at) %></td>
            <td class="Table-cell flex sm:justify-end">
              <.link navigate={Routes.users_path(@socket, :edit, user)} class="text-red-500">
                <I.pencil class="h-5 w-5" />
              </.link>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
