defmodule MaydayWeb.WebhookController do
  use MaydayWeb, :controller

  alias Mayday.Conversations

  def create(conn, %{"data" => %{"payload" => payload}} = params) do
    if Map.get(params, "secret") == Application.get_env(:mayday, :telnyx_webhook_secret) do
      %{
        "from" => %{"phone_number" => "+1" <> from},
        "text" => body,
        "to" => [%{"phone_number" => "+1" <> to} | _]
      } = payload

      Conversations.create_contact_response(from, to, body)

      resp(conn, 204, "")
    else
      resp(conn, 401, "")
    end
  end
end
