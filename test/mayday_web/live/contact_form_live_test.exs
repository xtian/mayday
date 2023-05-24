defmodule MaydayWeb.ContactFormLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "creates a new contact", %{conn: conn} do
    {:ok, view, _} = live(conn, Routes.contacts_path(conn, :new))

    params = Map.delete(params_for(:contact), :tags)

    view |> form(tid(:contact_form), %{contact: params}) |> render_submit()

    assert %{"info" => _} = assert_redirected(view, Routes.contacts_path(conn, :index))

    {:ok, _, html} = live(conn, Routes.contacts_path(conn, :index))
    assert html =~ params.first_name
    assert html =~ params.phone_number
  end

  test "updates an existing contact", %{conn: conn} do
    contact = insert(:contact)

    {:ok, view, _} = live(conn, Routes.contacts_path(conn, :edit, contact.id))

    new_name = unique_string()

    view |> form(tid(:contact_form), %{contact: %{first_name: new_name}}) |> render_submit()

    assert %{"info" => _} = assert_redirected(view, Routes.contacts_path(conn, :index))

    {:ok, _, html} = live(conn, Routes.contacts_path(conn, :index))
    assert html =~ new_name
  end

  test "deletes an existing contact", %{conn: conn} do
    contact = insert(:contact)

    {:ok, view, _} = live(conn, Routes.contacts_path(conn, :edit, contact.id))

    view |> element(tid(:delete_contact)) |> render_click()

    assert %{"info" => _} = assert_redirected(view, Routes.contacts_path(conn, :index))

    {:ok, _, html} = live(conn, Routes.contacts_path(conn, :index))
    refute html =~ contact.first_name
  end
end
