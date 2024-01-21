defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.Chat

  @impl true
  def mount(_params, _session, socket) do
    room = Chat.get_first_room!()
    messages = Chat.list_messages_in_room(room)
    {:ok, assign(socket, messages: messages, room: room)}
  end

  defp message_timestamp(message) do
    Timex.format!(message.inserted_at, "%-l:%M %p", :strftime)
  end
end
