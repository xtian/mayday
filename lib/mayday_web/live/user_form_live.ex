defmodule MaydayWeb.UserFormLive do
  use MaydayWeb, :live_view

  alias Mayday.Accounts

  @impl true
  def mount(params, _, socket) do
    params
    |> case do
      %{"id" => id} ->
        user = Accounts.get_user!(id)
        [changeset: Accounts.change_user(user, %{}), user: user, page_title: "Update User"]

      _ ->
        [changeset: Accounts.change_user(%{}), user: nil, page_title: "Create New User"]
    end
    |> then(&{:ok, assign(socket, &1)})
  end

  @impl true
  def handle_event("deactivate", %{"id" => id}, socket) do
    Accounts.deactivate_user(id)

    socket =
      socket
      |> put_flash(:info, "User deactivated")
      |> push_redirect(to: Routes.users_path(socket, :index))

    {:noreply, socket}
  end

  def handle_event("save", %{"user" => params}, %{assigns: assigns} = socket) do
    case Accounts.save_user(assigns.user, params) do
      {:ok, user} ->
        message =
          if assigns.user do
            "User saved"
          else
            "Invite sent"
          end

        Accounts.deliver_user_invite_instructions(
          user,
          &Routes.user_invitation_url(socket, :edit, &1)
        )

        socket =
          socket
          |> put_flash(:info, message)
          |> push_redirect(to: Routes.users_path(socket, :index))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("validate", %{"user" => params}, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, :changeset, Accounts.change_user(assigns.user, params))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.wrapper>
      <.back_link to={Routes.users_path(@socket, :index)} />

      <div class="flex max-w-lg justify-between">
        <h2 class="text-3xl font-bold"><%= @page_title %></h2>

        <%= if @user != nil and @user != @current_user do %>
          <button
            type="button"
            class="flex items-center space-x-2 text-red-500"
            data-confirm="Are you sure you want to deactivate this user? This cannot be undone."
            phx-click="deactivate"
            phx-value-id={@user.id}
            {tid(:delete_user)}
          >
            <I.x_circle class="h-5 w-5" />
            <span>Deactivate</span>
          </button>
        <% end %>
      </div>

      <.form :let={f} for={@changeset} phx-change="validate" phx-submit="save" class="flex flex-col" {tid(:user_form)}>
        <div class="flex max-w-lg flex-col space-y-4">
          <div class="flex space-x-4">
            <label class="grow">
              <div class="mb-2">First Name</div>
              <%= text_input(f, :first_name, required: true, class: "Input") %>
            </label>

            <label class="grow">
              <div class="mb-2">Last Name</div>
              <%= text_input(f, :last_name, required: true, class: "Input") %>
            </label>
          </div>

          <%= error_tag(f, :first_name) %>
          <%= error_tag(f, :last_name) %>

          <label>
            <div class="mb-2">Email</div>
            <%= email_input(f, :email, required: true, class: "Input") %>
          </label>
          <%= error_tag(f, :email) %>

          <label>
            <div class="mb-2">Role</div>
            <%= enum_select(f, :role, &String.capitalize("#{&1}"), class: "Input !w-auto !pr-10") %>
          </label>

          <button class="Btn Btn--primary self-end">
            <%= if @user do %>
              Save
            <% else %>
              Send Invite
            <% end %>
          </button>
        </div>
      </.form>
    </.wrapper>
    """
  end
end
