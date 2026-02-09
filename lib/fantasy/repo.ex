defmodule Fantasy.Repo do
  use Ecto.Repo,
    otp_app: :fantasy,
    adapter: Ecto.Adapters.SQLite3
end
