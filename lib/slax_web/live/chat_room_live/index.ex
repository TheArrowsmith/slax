defmodule SlaxWeb.ChatRoomLive.Index do
  use SlaxWeb, :live_view

  alias Slax.Chat

  @impl true
  def render(assigns) do
    ~H"""
    <main class="flex-1 p-6 max-w-4xl mx-auto">
      <div class="mb-4">
        <h2 class="text-xl font-semibold">All rooms</h2>
      </div>
      <div class="bg-slate-50 border rounded">
        <div class="divide-y">
          <div
            :for={{id, room} <- @streams.rooms}
            phx-click="view-room"
            phx-value-id={room.id}
            id={id}
            class="cursor-pointer p-4 flex justify-between items-center group first:rounded-t last:rounded-b"
          >
            <div>
              <div class="font-medium mb-1">
                #<%= room.name %>
                <span class="mx-1 text-gray-500 font-light text-sm opacity-0 group-hover:opacity-100">
                  View room
                </span>
              </div>
              <div class="text-gray-500 text-sm">
                <span class="text-green-600 font-bold">✓ Joined</span>
                <span class="mx-1">·</span>
                N members
                <%= if room.topic do %>
                  <span class="mx-1">·</span>
                  <%= room.topic %>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    rooms = Chat.list_rooms()
    {:ok, stream(socket, :rooms, rooms)}
  end

  @impl true
  def handle_event("view-room", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/rooms/#{id}")}
  end
end
