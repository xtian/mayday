defmodule MaydayWeb.UserInvitationController do
  use MaydayWeb, :controller

  alias Mayday.Accounts

  def edit(conn, %{"token" => token}) do
    case Accounts.fetch_user_by_confirm_token(token) do
      {:ok, user} ->
        changeset = Accounts.change_user_invite(user)
        render(conn, "edit.html", changeset: changeset, page_title: "Accept invite", token: token)

      _ ->
        send_resp(conn, 404, "Invalid invite link")
    end
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def update(conn, %{"token" => token, "user" => params}) do
    case Accounts.accept_user_invite(token, params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Account set up successfully")
        |> redirect(to: "/")

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset, page_title: "Accept invite", token: token)

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the invite link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when confirmed_at != nil ->
            redirect(conn, to: Routes.dashboard_path(conn, :index))

          %{} ->
            conn
            |> put_flash(:error, "Invite link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end
