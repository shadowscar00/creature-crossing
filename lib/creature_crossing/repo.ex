defmodule CreatureCrossing.Repo do
  use Ecto.Repo,
    otp_app: :creature_crossing,
    adapter: Ecto.Adapters.SQLite3
end
