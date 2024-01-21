defmodule Slax.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string, null: false
      add :topic, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rooms, :name)
  end
end
