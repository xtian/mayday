defmodule MaydayWeb.ProvisionedNumbersLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "renders list of provisioned numbers", %{conn: conn} do
    number = insert(:provisioned_number)

    {:ok, _, html} = live(conn, Routes.provisioned_numbers_path(conn, :index))

    assert html =~ number.label
    assert html =~ number.phone_number
  end
end
