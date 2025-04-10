defmodule SlaxWeb.RoomController do
  use SlaxWeb, :controller

  alias Slax.Chat

  def redirect_to_first(conn, _params) do
    path =
      case Chat.list_joined_rooms(conn.assigns.current_user) do
        [] ->
          ~p"/rooms"

        [first | _] ->
          ~p"/rooms/#{first}"
      end

    redirect(conn, to: path)
  end
end
