defmodule DynamicOptimizationWeb.UserLiveAuthTest do
  use MaydayWeb.ConnCase, async: true

  test "owner can access all routes", %{conn: conn} do
    user = insert(:user, role: :owner)
    conn = log_in_user(conn, user)
    paths = build_paths(conn, user)

    for path <- paths.admin ++ paths.manager ++ paths.texter do
      assert conn |> get(path) |> response(200)
    end
  end

  test "admin can access all routes", %{conn: conn} do
    user = insert(:user, role: :admin)
    conn = log_in_user(conn, user)
    paths = build_paths(conn, user)

    for path <- paths.admin ++ paths.manager ++ paths.texter do
      assert conn |> get(path) |> response(200)
    end
  end

  test "manager can access manager and texter routes", %{conn: conn} do
    user = insert(:user, role: :manager)
    conn = log_in_user(conn, user)
    paths = build_paths(conn, user)

    for path <- paths.admin do
      assert conn |> get(path) |> redirected_to()
    end

    for path <- paths.manager ++ paths.texter do
      assert conn |> get(path) |> html_response(200)
    end
  end

  test "texter can only access texter routes", %{conn: conn} do
    user = insert(:user, role: :texter)
    conn = log_in_user(conn, user)
    paths = build_paths(conn, user)

    for path <- paths.admin ++ paths.manager do
      assert conn |> get(path) |> redirected_to()
    end

    for path <- paths.texter do
      assert conn |> get(path) |> html_response(200)
    end
  end

  test "deactivated can not access any routes", %{conn: conn} do
    user = insert(:user, role: :deactivated)
    conn = log_in_user(conn, user)
    paths = build_paths(conn, user)

    for path <- paths.admin ++ paths.manager ++ paths.texter do
      assert conn |> get(path) |> redirected_to()
    end
  end

  defp build_paths(conn, current_user) do
    conversation = insert(:conversation, user: current_user)
    campaign = conversation.campaign
    contact = conversation.contact
    user = conversation.user

    %{
      admin: [
        Routes.contacts_path(conn, :edit, contact.id),
        Routes.contacts_path(conn, :index),
        Routes.contacts_path(conn, :new),
        Routes.file_path(conn, :download_contacts),
        Routes.file_path(conn, :download_responses, campaign.id),
        Routes.provisioned_numbers_path(conn, :index),
        Routes.provisioned_numbers_path(conn, :new),
        Routes.users_path(conn, :edit, user.id),
        Routes.users_path(conn, :index),
        Routes.users_path(conn, :new)
      ],
      manager: [
        Routes.campaigns_path(conn, :edit, campaign.id),
        Routes.campaigns_path(conn, :index),
        Routes.campaigns_path(conn, :new),
        Routes.campaigns_path(conn, :show, campaign.id)
      ],
      texter: [
        Routes.conversations_path(conn, :index, campaign.id),
        Routes.conversations_path(conn, :show, campaign.id, conversation.id),
        Routes.dashboard_path(conn, :index)
      ]
    }
  end
end
