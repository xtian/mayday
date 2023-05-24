defmodule MaydayWeb.UserSessionController do
  use MaydayWeb, :controller

  alias Mayday.Accounts
  alias MaydayWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil, page_title: "Log in")
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.get_user_by_email_and_password(email, password) do
      %{role: role} = user when role != :deactivated ->
        UserAuth.log_in_user(conn, user, user_params)

      _ ->
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        render(conn, "new.html", error_message: "Invalid email or password", page_title: "Log in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
