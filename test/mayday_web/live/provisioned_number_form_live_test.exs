defmodule MaydayWeb.ProvisionedNumberFormLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "creates a new provisioned number", %{conn: conn} do
    {:ok, view, _} = live(conn, Routes.provisioned_numbers_path(conn, :new))

    params = params_for(:provisioned_number)

    view |> form(tid(:provisioned_number_form), %{provisioned_number: params}) |> render_submit()

    assert %{"info" => _} = assert_redirected(view, Routes.provisioned_numbers_path(conn, :index))

    {:ok, _, html} = live(conn, Routes.provisioned_numbers_path(conn, :index))
    assert html =~ params.label
    assert html =~ params.phone_number
  end

  test "updates an existing provisioned number", %{conn: conn} do
    number = insert(:provisioned_number)

    {:ok, view, _} = live(conn, Routes.provisioned_numbers_path(conn, :edit, number.phone_number))

    label = Faker.Lorem.word()

    view
    |> form(tid(:provisioned_number_form), %{provisioned_number: %{label: label}})
    |> render_submit()

    {:ok, _, html} = live(conn, Routes.provisioned_numbers_path(conn, :index))
    assert html =~ label
  end
end
