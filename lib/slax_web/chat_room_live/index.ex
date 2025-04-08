defmodule SlaxWeb.ChatRoomLive.Index do
  use SlaxWeb, :live_view

  alias Slax.Chat

  def render(assigns) do
    ~H"""
    <main class="flex-1 p-6 max-w-4xl mx-auto">
      <div class="mb-4">
        <h1 class="text-xl font-semibold">{@page_title}</h1>
      </div>
      <div class="bg-slate-50 border rounded">
        <div id="rooms" class="divide-y" phx-update="stream">
          <.link
            :for={{id, {room, joined?}} <- @streams.rooms}
            class="cursor-pointer p-4 flex justify-between items-center group first:rounded-t last:rounded-b"
            id={id}
            navigate={~p"/rooms/#{room}"}
          >
            <div>
              <div class="font-medium mb-1">
                #{room.name}
                <span class="mx-1 text-gray-500 font-light text-sm hidden group-hover:inline group-focus:inline">
                  View room
                </span>
              </div>
              <div class="text-gray-500 text-sm">
                <%= if joined? do %>
                  <span class="text-green-600 font-bold">✓ Joined</span>
                <% end %>
                <%= if joined? && room.topic do %>
                  <span class="mx-1">·</span>
                <% end %>
                <%= if room.topic do %>
                  {room.topic}
                <% end %>
              </div>
            </div>
          </.link>
        </div>
      </div>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    rooms = Chat.list_rooms_with_joined(socket.assigns.current_user)

    socket =
      socket
      |> assign(:page_title, "All rooms")
      |> stream_configure(:rooms, dom_id: fn {room, _} -> "rooms-#{room.id}" end)
      |> stream(:rooms, rooms)

    {:ok, socket}
  end
end
