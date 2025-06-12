defmodule Slax.Repo do
  use Ecto.Repo,
    otp_app: :slax,
    adapter: Ecto.Adapters.Postgres

  use Paginator
end
