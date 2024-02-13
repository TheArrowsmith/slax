defmodule Slax.Chat do
  alias Slax.Repo
  alias Slax.Chat.Room
  alias Slax.Chat.Message

  import Ecto.Query

  def get_first_room! do
    Repo.one(from r in Room, limit: 1)
  end

  def list_messages_in_room(%Room{id: room_id}) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> order_by([m], asc: :inserted_at, asc: :id)
    |> preload(:user)
    |> Repo.all()
  end
end
