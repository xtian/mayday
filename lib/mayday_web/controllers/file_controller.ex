defmodule MaydayWeb.FileController do
  use MaydayWeb, :controller

  alias Mayday.{Campaigns, Contacts}

  @contacts_header ["Last Name", "First Name", "Phone Number", "Tags"]

  def download_contacts(conn, _) do
    rows =
      Enum.map(Contacts.list_contacts(), fn contact ->
        [contact.last_name, contact.first_name, contact.phone_number, contact.tags]
      end)

    send_download(conn, {:binary, NimbleCSV.RFC4180.dump_to_iodata([@contacts_header | rows])},
      content_type: "text/csv",
      disposition: :attachment,
      filename: "contacts"
    )
  end

  def download_responses(conn, %{"id" => campaign_id}) do
    campaign = Campaigns.get_campaign!(campaign_id)

    header = [
      "Last Name",
      "First Name",
      "Phone Number"
      | Enum.map(campaign.script_messages, & &1.report_label)
    ]

    header = List.insert_at(header, -1, "Notes")

    rows =
      Enum.map(campaign.conversations, fn conversation ->
        row = [
          conversation.contact.last_name,
          conversation.contact.first_name,
          conversation.contact.phone_number
          | Enum.map(conversation.survey_responses, &(&1.value || ""))
        ]

        List.insert_at(row, -1, conversation.notes || "")
      end)

    send_download(conn, {:binary, NimbleCSV.RFC4180.dump_to_iodata([header | rows])},
      content_type: "text/csv",
      disposition: :attachment,
      filename: String.replace(campaign.name, ~r/[^\w- ]/, "")
    )
  end
end
