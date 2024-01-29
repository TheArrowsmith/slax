defmodule Slax.Chat.RoomMembership do
  use Ecto.Schema
  import Ecto.Changeset

  alias Slax.Chat.Room
  alias Slax.Accounts.User

  schema "room_memberships" do
    belongs_to :user, User
    belongs_to :room, Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room_membership, attrs) do
    room_membership
    |> cast(attrs, [])
    |> validate_required([])
  end
end
