defmodule MaydayWeb.UserFormLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Mayday.{Accounts, Repo}

  setup :register_and_log_in_user

  test "creates a new user", %{conn: conn} do
    {:ok, view, _} = live(conn, Routes.users_path(conn, :new))

    params = Map.delete(params_for(:user), :hashed_password)

    view |> form(tid(:user_form), %{user: params}) |> render_submit()

    assert %{"info" => _} = assert_redirected(view, Routes.users_path(conn, :index))

    {:ok, _, html} = live(conn, Routes.users_path(conn, :index))
    {:safe, last_name} = Phoenix.HTML.html_escape(params.last_name)

    assert html =~ params.first_name
    assert html =~ last_name

    # Sends invite
    [_, user] = Repo.all(Accounts.User)
    assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
  end

  test "updates an existing user", %{conn: conn} do
    user = insert(:user)

    {:ok, view, _} = live(conn, Routes.users_path(conn, :edit, user.id))

    new_name = unique_string()

    view
    |> form(tid(:user_form), %{user: %{first_name: new_name}})
    |> render_submit()

    assert %{"info" => _} = assert_redirected(view, Routes.users_path(conn, :index))

    {:ok, _, html} = live(conn, Routes.users_path(conn, :index))
    assert html =~ new_name
  end
end
