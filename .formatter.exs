[
  plugins: [TailwindFormatter.MultiFormatter],
  import_deps: [:ecto, :ecto_sql, :phoenix, :phoenix_live_view],
  inputs: [
    "*.{ex,exs,heex}",
    "priv/*/seeds.exs",
    "{config,lib,test}/**/*.{ex,exs,heex}"
  ],
  heex_line_length: 120
]
