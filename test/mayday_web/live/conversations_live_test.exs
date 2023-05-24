defmodule MaydayWeb.ConversationsLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  setup %{user: user} do
    {:ok, conversation: insert(:conversation, user: user)}
  end

  test "renders list of conversations", %{conn: conn, conversation: conversation} do
    {:ok, _, html} = live(conn, Routes.conversations_path(conn, :index, conversation.campaign))

    assert html =~ conversation.contact.first_name
  end

  test "updates list when message is received", %{conn: conn, conversation: conversation} do
    Mayday.subscribe("conversations:#{conversation.id}")

    {:ok, view, _} = live(conn, Routes.conversations_path(conn, :index, conversation.campaign))

    post_message(conversation, Faker.Lorem.sentence())

    assert_receive {:new_message, _}

    # TODO: Bad assertion
    assert view |> element(tid(:conversations)) |> render() =~ "bg-red-500"
  end

  test "can jump to next available conversation", %{conn: conn, conversation: conversation} do
    next_conversation = insert(:conversation, campaign: conversation.campaign, user: nil)

    {:ok, view, _} = live(conn, Routes.conversations_path(conn, :index, conversation.campaign))

    view
    |> element(tid(:next_conversation))
    |> render_click()

    assert_redirected(
      view,
      Routes.conversations_path(conn, :show, conversation.campaign, next_conversation)
    )
  end
end
