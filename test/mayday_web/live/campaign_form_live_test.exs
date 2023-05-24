defmodule MaydayWeb.CampaignFormLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "creates a new campaign", %{conn: conn} do
    insert(:provisioned_number)

    {:ok, view, _} = live(conn, Routes.campaigns_path(conn, :new))

    new_name = unique_string()

    view |> element(tid(:add_script_message)) |> render_click()

    view
    |> form(tid(:campaign_form), %{
      campaign: %{
        name: new_name,
        script_messages: %{
          0 => %{message_template: unique_string()},
          1 => %{message_template: unique_string()}
        }
      }
    })
    |> render_submit()

    assert %{"info" => _} = assert_redirected(view, Routes.campaigns_path(conn, :index))

    {:ok, _, html} = live(conn, Routes.campaigns_path(conn, :index))
    assert html =~ new_name
  end

  test "updates an existing campaign", %{conn: conn} do
    campaign = insert(:campaign)

    {:ok, view, _} = live(conn, Routes.campaigns_path(conn, :edit, campaign.id))

    new_name = unique_string()

    view
    |> form(tid(:campaign_form), %{
      campaign: %{
        name: new_name,
        script_messages: %{0 => %{message_template: unique_string()}}
      }
    })
    |> render_submit()

    assert %{"info" => _} = assert_redirected(view, Routes.campaigns_path(conn, :index))

    {:ok, _, html} = live(conn, Routes.campaigns_path(conn, :index))
    assert html =~ new_name
  end

  test "deletes an existing campaign", %{conn: conn} do
    campaign = insert(:campaign)

    {:ok, view, _} = live(conn, Routes.campaigns_path(conn, :edit, campaign.id))

    view |> element(tid(:delete_campaign)) |> render_click()

    assert %{"info" => _} = assert_redirected(view, Routes.campaigns_path(conn, :index))

    {:ok, _, html} = live(conn, Routes.campaigns_path(conn, :index))
    refute html =~ campaign.name
  end
end
