defmodule Slax.Repo do
  use Ecto.Repo,
    otp_app: :slax,
    adapter: Ecto.Adapters.Postgres
end
