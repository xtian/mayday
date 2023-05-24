defmodule MaydayWeb.UserInvitationControllerTest do
  use MaydayWeb.ConnCase, async: true

  import Mayday.AccountsFixtures

  alias Mayday.Accounts
  alias Mayday.Repo

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/accept_invite/:token" do
    test "renders the invite page", %{conn: conn} do
      user = insert(:user)

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_invite_instructions(user, url)
        end)

      conn = get(conn, Routes.user_invitation_path(conn, :edit, token))
      response = html_response(conn, 200)
      assert response =~ "Accept invite"

      form_action = Routes.user_invitation_path(conn, :update, token)
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "PUT /users/accept_invite/:token" do
    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_invite_instructions(user, url)
        end)

      conn =
        put(conn, Routes.user_invitation_path(conn, :update, token), %{
          user: %{password: Faker.Lorem.sentence()}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Account set up successfully"
      assert Accounts.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(Accounts.UserToken) == []

      # When not logged in
      conn =
        put(conn, Routes.user_invitation_path(conn, :update, token), %{
          user: %{password: Faker.Lorem.sentence()}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Invite link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_user(user)
        |> put(Routes.user_invitation_path(conn, :update, token), %{
          user: %{password: Faker.Lorem.sentence()}
        })

      assert redirected_to(conn) == Routes.dashboard_path(conn, :index)
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      conn =
        put(conn, Routes.user_invitation_path(conn, :update, "oops"), %{
          user: %{password: Faker.Lorem.sentence()}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Invite link is invalid or it has expired"
      refute Accounts.get_user!(user.id).confirmed_at
    end
  end
end
