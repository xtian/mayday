defmodule MaydayWeb.UserLiveAuth do
  import Phoenix.{Component, LiveView}

  alias Mayday.Accounts
  alias MaydayWeb.Router.Helpers, as: Routes

  def on_mount(role, _, %{"user_token" => user_token}, socket) do
    %{assigns: %{current_user: current_user}} =
      socket =
      assign_new(socket, :current_user, fn -> Accounts.get_user_by_session_token(user_token) end)

    if current_user != nil and can?(role, current_user.role) do
      {:cont, socket}
    else
      {:halt, push_redirect(socket, to: Routes.user_session_path(socket, :new))}
    end
  end

  def on_mount(_, _, _, socket) do
    {:halt, push_redirect(socket, to: Routes.user_session_path(socket, :new))}
  end

  defp can?(_, :deactivated), do: false
  defp can?(role, role), do: true
  defp can?(_, :admin), do: true
  defp can?(_, :owner), do: true
  defp can?(:texter, :manager), do: true
  defp can?(_, _), do: false
end
