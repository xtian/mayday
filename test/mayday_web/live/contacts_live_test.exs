defmodule MaydayWeb.ContactsLiveTest do
  use MaydayWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Mayday.{Contacts.Contact, Repo}

  setup :register_and_log_in_user

  test "renders list of contacts", %{conn: conn} do
    [contact_a, contact_b] = insert_list(2, :contact)

    {:ok, _, html} = live(conn, Routes.contacts_path(conn, :index))

    assert html =~ contact_a.first_name
    assert html =~ contact_b.first_name
  end

  test "accepts uploads of contact CSVs", %{conn: conn} do
    import Faker.Person

    contact_count = :rand.uniform(5)

    content =
      [["Last Name", "First Name", "Phone Number", "Tags"]]
      |> Stream.concat(
        Stream.repeatedly(fn ->
          tags =
            (&unique_string/0)
            |> Stream.repeatedly()
            |> Enum.take(:rand.uniform(5) - 1)
            |> Enum.join(" ")

          [last_name(), first_name(), random_phone(), tags]
        end)
      )
      |> Stream.take(contact_count + 1)
      |> NimbleCSV.RFC4180.dump_to_iodata()
      |> IO.iodata_to_binary()

    {:ok, view, _} = live(conn, Routes.contacts_path(conn, :index))
    name = "#{Faker.Lorem.word()}.csv"

    csv =
      file_input(view, tid(:csv_upload), :contacts_import, [
        %{
          last_modified: DateTime.to_unix(DateTime.utc_now()),
          name: name,
          content: content,
          size: IO.iodata_length(content),
          type: "text/csv"
        }
      ])

    render_upload(csv, name)

    assert Repo.aggregate(Contact, :count) == contact_count
  end
end
