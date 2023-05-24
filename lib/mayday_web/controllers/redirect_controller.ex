defmodule MaydayWeb.RedirectController do
  use MaydayWeb, :controller

  def show(conn, _) do
    redirect(conn, to: Routes.dashboard_path(conn, :index))
  end
end
