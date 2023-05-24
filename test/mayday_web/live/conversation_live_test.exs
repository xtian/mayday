defmodule MaydayWeb.ConversationLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Mox
  import Phoenix.LiveViewTest

  alias Mayday.{Contacts, Repo}

  setup :register_and_log_in_user
  setup :set_mox_from_context
  setup :verify_on_exit!

  @http_client Mayday.HTTPClientMock

  setup %{user: user} do
    {:ok, conversation: insert(:conversation, user: user)}
  end

  test "can send a message", %{conn: conn, conversation: conversation} do
    {:ok, view, _} =
      live(conn, Routes.conversations_path(conn, :show, conversation.campaign, conversation))

    test_pid = self()

    stub(@http_client, :post_json, fn _, headers, body ->
      send(test_pid, {:post_json, headers, body})
      {:ok, %{status: 200}}
    end)

    message = Faker.Lorem.sentence()

    view |> form(tid(:message_form), %{message: %{body: message}}) |> render_submit()

    assert_receive {:post_json, [{"authorization", _}], payload}
    assert String.ends_with?(payload.from, conversation.campaign.phone_number)
    assert String.ends_with?(payload.to, conversation.contact.phone_number)
    assert payload.text == message
  end

  test "can receive a message", %{conn: conn, conversation: conversation} do
    Mayday.subscribe("conversations:#{conversation.id}")

    {:ok, view, _} =
      live(conn, Routes.conversations_path(conn, :show, conversation.campaign, conversation))

    message = Faker.Lorem.sentence()
    post_message(conversation, message)

    assert_receive {:new_message, _}
    assert view |> element(tid(:messages)) |> render() =~ message
  end

  test "can fill out campaign survey", %{conn: conn, conversation: conversation} do
    {:ok, view, _} =
      live(conn, Routes.conversations_path(conn, :show, conversation.campaign, conversation))

    view
    |> form(tid(:survey_form), %{conversation: %{survey_responses: %{"0" => %{value: true}}}})
    |> render_change()

    assert [%{value: "true"}] = Repo.reload(conversation).survey_responses
  end

  test "can opt out contact", %{conn: conn, conversation: conversation} do
    {:ok, view, _} =
      live(conn, Routes.conversations_path(conn, :show, conversation.campaign, conversation))

    view
    |> element(tid(:opt_out))
    |> render_click()

    assert %{"info" => _} =
             assert_redirected(
               view,
               Routes.conversations_path(conn, :index, conversation.campaign)
             )

    assert Repo.get(Contacts.Contact, conversation.contact.id) == nil
    assert Repo.aggregate(Contacts.OptOut, :count) == 1
  end

  test "redirects to index if no next conversation", %{conn: conn, conversation: conversation} do
    {:ok, view, _} =
      live(conn, Routes.conversations_path(conn, :show, conversation.campaign, conversation))

    view
    |> element(tid(:next_conversation))
    |> render_click()

    assert %{"info" => _} =
             assert_redirected(
               view,
               Routes.conversations_path(conn, :index, conversation.campaign)
             )
  end

  test "can jump to next available conversation", %{conn: conn, conversation: conversation} do
    next_conversation = insert(:conversation, campaign: conversation.campaign, user: nil)

    {:ok, view, _} =
      live(conn, Routes.conversations_path(conn, :show, conversation.campaign, conversation))

    view
    |> element(tid(:next_conversation))
    |> render_click()

    assert_redirected(
      view,
      Routes.conversations_path(conn, :show, conversation.campaign, next_conversation)
    )
  end
end
