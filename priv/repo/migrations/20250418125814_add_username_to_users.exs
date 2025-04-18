defmodule Slax.Repo.Migrations.AddUsernameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :citext
    end

    execute """
            UPDATE users
            SET username = initcap(substring(email FROM '^[^@]+'));
            """,
            ""

    alter table(:users) do
      modify :username, :citext, null: false, from: {:citext, null: true}
    end

    create unique_index(:users, :username)
  end
end
