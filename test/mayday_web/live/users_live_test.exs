defmodule MaydayWeb.UsersLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "renders list of users", %{conn: conn, user: admin} do
    deactivated = insert(:user, role: :deactivated)
    manager = insert(:user, role: :manager)
    texter = insert(:user, role: :texter)

    {:ok, view, _} = live(conn, Routes.users_path(conn, :index))

    assert view |> element(tid(:admins)) |> render() =~ admin.first_name
    assert view |> element(tid(:managers)) |> render() =~ manager.first_name
    assert view |> element(tid(:texters)) |> render() =~ texter.first_name
    assert view |> element(tid(:deactivated)) |> render() =~ deactivated.first_name
  end
end
