defmodule MaydayWeb.DashboardLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "renders list of started campaigns", %{conn: conn} do
    [campaign_a, campaign_b] = insert_list(2, :campaign, started_at: DateTime.utc_now())
    campaign_c = insert(:campaign)

    {:ok, _, html} = live(conn, Routes.dashboard_path(conn, :index))

    assert html =~ campaign_a.name
    assert html =~ campaign_b.name
    refute html =~ campaign_c.name
  end
end
