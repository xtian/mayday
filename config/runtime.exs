import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# Start the phoenix server if environment is set and running in a  release
if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :mayday, MaydayWeb.Endpoint, server: true
end

if config_env() == :prod do
  config :mayday,
    email_host: System.fetch_env!("EMAIL_HOST"),
    telnyx_api_key: System.fetch_env!("TELNYX_API_KEY"),
    telnyx_webhook_secret: System.fetch_env!("TELNYX_WEBHOOK_SECRET")

  config :mayday, Mayday.Repo,
    url: System.fetch_env!("DATABASE_URL"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: if(System.get_env("ECTO_IPV6"), do: [:inet6], else: [])

  config :mayday, MaydayWeb.Endpoint,
    url: [host: System.fetch_env!("PHX_HOST"), scheme: "https", port: 443],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
    server: true

  ## Configuring the mailer
  config :mayday, Mayday.Mailer,
    adapter: Swoosh.Adapters.Mailgun,
    api_key: System.fetch_env!("MAILGUN_API_KEY"),
    domain: System.fetch_env!("MAILGUN_DOMAIN")

  config :sentry,
    dsn: System.fetch_env!("SENTRY_DSN"),
    environment_name: :prod,
    enable_source_code_context: true,
    root_source_code_path: File.cwd!(),
    tags: %{
      env: "production"
    },
    included_environments: [:prod]

  config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Mayday.Finch
end
