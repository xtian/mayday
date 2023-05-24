defmodule MaydayWeb.PingController do
  use MaydayWeb, :controller

  def index(conn, _params) do
    text(conn, "ok")
  end
end
