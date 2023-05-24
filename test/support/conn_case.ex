defmodule MaydayWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use MaydayWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import Phoenix.ConnTest

  @endpoint MaydayWeb.Endpoint

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import MaydayWeb.ConnCase
      import Mayday.Factory

      alias MaydayWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint MaydayWeb.Endpoint
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mayday.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    {:ok, conn: build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = Mayday.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = Mayday.Accounts.generate_user_session_token(user)

    conn
    |> init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  def post_message(%{campaign: campaign, contact: contact}, message) do
    secret = Application.get_env(:mayday, :telnyx_webhook_secret)

    data = %{
      payload: %{
        from: %{phone_number: "+1#{contact.phone_number}"},
        text: message,
        to: [%{phone_number: "+1#{campaign.phone_number}"}]
      }
    }

    conn = build_conn()
    path = MaydayWeb.Router.Helpers.webhook_path(conn, :create)

    post(conn, path, %{secret: secret, data: data})
  end

  def count_children(html, identifier) do
    html |> Floki.find(identifier) |> Enum.count()
  end

  def tid(id) do
    [{attribute, _}] = MaydayWeb.Helpers.tid(id)
    "[#{attribute}]"
  end
end
