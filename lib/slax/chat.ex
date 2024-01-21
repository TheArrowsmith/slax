defmodule Slax.Chat do
  alias Slax.Repo
  alias Slax.Chat.Room
  alias Slax.Chat.Message

  import Ecto.Query

  def get_first_room! do
    Repo.one(from r in Room, limit: 1)
  end

  def get_room!(id) do
    Repo.get!(Room, id)
  end

  def list_rooms do
    Repo.all(Room, order_by: [asc: :name])
  end

  def change_room(room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  def list_messages_in_room(%Room{id: room_id}) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> order_by([m], asc: :inserted_at, asc: :id)
    |> preload(:user)
    |> Repo.all()
  end

  def change_message(message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def create_message(room, attrs, user) do
    %Message{room: room, user: user}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end
end
