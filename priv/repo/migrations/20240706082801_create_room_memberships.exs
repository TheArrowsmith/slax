defmodule Slax.Repo.Migrations.CreateRoomMemberships do
  use Ecto.Migration

  def change do
    create table(:room_memberships) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :room_id, references(:rooms, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:room_memberships, [:user_id])
    create index(:room_memberships, [:room_id])
    create unique_index(:room_memberships, [:user_id, :room_id])
  end
end
