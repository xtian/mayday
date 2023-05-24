defmodule Mayday.Repo do
  use Ecto.Repo,
    otp_app: :mayday,
    adapter: Ecto.Adapters.Postgres
end
