defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.Chat.Room
  alias Slax.Repo

  def render(assigns) do
    ~H"""
    <div class="flex flex-col shrink-0 w-64 bg-slate-100">
      <div class="flex justify-between items-center shrink-0 h-16 border-b border-slate-300 px-4">
        <div class="flex flex-col gap-1.5">
          <h1 class="text-lg font-bold text-gray-800">
            Slax
          </h1>
        </div>
      </div>
      <div class="mt-4 overflow-auto">
        <div class="flex items-center h-8 px-3">
          <span class="ml-2 leading-none font-medium text-sm">Rooms</span>
        </div>
        <div id="rooms-list">
          <.room_link :for={room <- @rooms} room={room} active={room.id == @room.id} />
        </div>
      </div>
    </div>
    <div class="flex flex-col grow shadow-lg">
      <div class="flex justify-between items-center shrink-0 h-16 bg-white border-b border-slate-300 px-4">
        <div class="flex flex-col gap-1.5">
          <h1 class="text-sm font-bold leading-none">
            #{@room.name}
          </h1>
          <div
            class={["text-xs leading-none h-3.5", @hide_topic? && "text-slate-600"]}
            phx-click="toggle-topic"
          >
            <%= if @hide_topic? do %>
              [Topic hidden]
            <% else %>
              {@room.topic}
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :active, :boolean, required: true
  attr :room, Room, required: true

  defp room_link(assigns) do
    ~H"""
    <.link
      class={[
        "flex items-center h-8 text-sm pl-8 pr-3",
        (@active && "bg-slate-300") || "hover:bg-slate-300"
      ]}
      patch={~p"/rooms/#{@room}"}
    >
      <.icon name="hero-hashtag" class="h-4 w-4" />
      <span class={["ml-2 leading-none", @active && "font-bold"]}>
        {@room.name}
      </span>
    </.link>
    """
  end

  def mount(_params, _session, socket) do
    rooms = Repo.all(Room)

    {:ok, assign(socket, rooms: rooms)}
  end

  def handle_params(params, _uri, socket) do
    rooms = socket.assigns.rooms

    room =
      case Map.fetch(params, "id") do
        {:ok, id} ->
          Repo.get!(Room, id)

        :error ->
          List.first(rooms)
      end

    {:noreply, assign(socket, room: room, hide_topic?: false)}
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply, update(socket, :hide_topic?, &(!&1))}
  end
end
