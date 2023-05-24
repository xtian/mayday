defmodule MaydayWeb.CoreComponents do
  use Phoenix.Component, global_prefixes: ~w(x-)

  defdelegate form(assigns), to: Phoenix.Component
end
