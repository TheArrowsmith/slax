defmodule Slax.Chat do
  alias Slax.Chat.Room
  alias Slax.Repo

  def list_rooms do
    Repo.all(Room)
  end

  def get_room!(id) do
    Repo.get!(Room, id)
  end
end
