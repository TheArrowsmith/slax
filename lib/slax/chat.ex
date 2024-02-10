defmodule Slax.Chat do
  alias Slax.Repo
  alias Slax.Accounts.User
  alias Slax.Chat.{Room, RoomMembership}
  alias Slax.Chat.Message

  import Ecto.Changeset
  import Ecto.Query

  @pubsub Slax.PubSub

  def get_first_room! do
    Repo.one(from r in Room, limit: 1)
  end

  def get_room!(id) do
    Repo.get!(Room, id)
  end

  def list_rooms do
    Repo.all(Room, order_by: [asc: :name])
  end

  def list_rooms_with_unread_counts(user) do
    query =
      from r in Room,
        left_join: m in RoomMembership,
        on: r.id == m.room_id and m.user_id == ^user.id,
        select: {r, not is_nil(m.id)}

    Repo.all(query)
  end

  def list_rooms_with_membership(user) do
    query =
      from r in Room,
        left_join: m in RoomMembership,
        on: r.id == m.room_id and m.user_id == ^user.id,
        select: {r, not is_nil(m.id)}

    Repo.all(query)
  end

  def join_room(room, user) do
    Repo.insert(%RoomMembership{room: room, user: user})
  end

  def toggle_room_membership(room, user) do
    case get_membership(room, user) do
      %RoomMembership{} = membership ->
        Repo.delete(membership)

      nil ->
        join_room(room, user)
    end
  end

  defp get_membership(room, user) do
    Repo.get_by(RoomMembership, room_id: room.id, user_id: user.id)
  end

  def list_joined_rooms(%User{} = user) do
    from(rm in RoomMembership,
      where: rm.user_id == ^user.id,
      join: r in assoc(rm, :room),
      left_join: m in Message,
      on: m.room_id == rm.room_id and m.id > rm.last_read_id,
      group_by: [r.id, rm.id],
      select: {r, count(m.id)}
    )
    |> Repo.all()
    |> Enum.sort_by(fn {room, _unread_count} -> room.name end)
  end

  def joined?(%Room{} = room, %User{} = user) do
    Repo.exists?(
      from rm in RoomMembership, where: rm.room_id == ^room.id and rm.user_id == ^user.id
    )
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

  def get_last_read_id(%Room{} = room, user) do
    case get_membership(room, user) do
      %RoomMembership{} = membership -> membership.last_read_id
      nil -> nil
    end
  end

  def update_last_read_id(room, user) do
    case get_membership(room, user) do
      %RoomMembership{} = membership ->
        id =
          from(m in Message, where: m.room_id == ^room.id, select: max(m.id))
          |> Repo.one()

        membership
        |> change(%{last_read_id: id})
        |> Repo.update()

      nil ->
        nil
    end
  end

  def change_message(message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def create_message(room, attrs, user) do
    with {:ok, message} <-
           %Message{room: room, user: user}
           |> Message.changeset(attrs)
           |> Repo.insert() do
      Phoenix.PubSub.broadcast!(@pubsub, topic(room.id), {:new_message, message})
      {:ok, message}
    end
  end

  def subscribe_to_rooms(rooms) do
    for room <- rooms do
      Phoenix.PubSub.subscribe(@pubsub, topic(room.id))
    end
  end

  defp topic(room_id), do: "chat_room:#{room_id}"

  def delete_message_by_id(id, %User{id: user_id}) do
    message = %Message{user_id: ^user_id} = Repo.get(Message, id)

    Repo.delete(message)

    Phoenix.PubSub.broadcast!(@pubsub, topic(message.room_id), {:message_deleted, message})
  end
end
