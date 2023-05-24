defmodule Mayday.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    if Application.get_env(:mayday, :sentry_dsn) do
      Logger.add_backend(Sentry.LoggerBackend)
    end

    children = [
      Mayday.Repo,
      MaydayWeb.Telemetry,
      {Phoenix.PubSub, name: Mayday.PubSub},
      MaydayWeb.Endpoint,
      {Finch, name: Mayday.Finch}
    ]

    opts = [strategy: :one_for_one, name: Mayday.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MaydayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
