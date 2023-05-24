defmodule MaydayWeb.CampaignsLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "renders list of campaigns", %{conn: conn} do
    [campaign_a, campaign_b] = insert_list(2, :campaign)

    {:ok, _, html} = live(conn, Routes.campaigns_path(conn, :index))

    assert html =~ campaign_a.name
    assert html =~ campaign_b.name
  end
end
