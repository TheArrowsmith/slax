defmodule SlaxWeb.ChatRoomLive.Index do
  use SlaxWeb, :live_view

  alias Phoenix.LiveView.JS
  alias Slax.Chat

  @impl true
  def render(assigns) do
    ~H"""
    <main class="flex-1 p-6 max-w-4xl mx-auto">
      <div class="flex justify-between mb-4 items-center">
        <h2 class="text-xl font-semibold">All rooms</h2>
        <button
          phx-click="show-form"
          class="bg-white font-semibold py-2 px-4 border border-slate-400 rounded shadow-sm"
        >
          Create room
        </button>
      </div>
      <div class="bg-slate-50 border rounded">
        <div class="divide-y">
          <div
            :for={{id, {room, joined?}} <- @streams.rooms}
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
                <%= if joined? do %>
                  <span class="text-green-600 font-bold">✓ Joined</span>
                  <span class="mx-1">·</span>
                <% end %>
                N members
                <%= if room.topic do %>
                  <span class="mx-1">·</span>
                  <%= room.topic %>
                <% end %>
              </div>
            </div>
            <button
              class="opacity-0 group-hover:opacity-100 bg-white hover:bg-gray-100 border border-gray-400 text-gray-700 px-3 py-1.5 w-24 rounded-sm font-bold"
              phx-click="toggle-room-membership"
              phx-value-id={room.id}
            >
              <%= if joined? do %>
                Leave
              <% else %>
                Join
              <% end %>
            </button>
          </div>
        </div>
      </div>
    </main>

    <.modal :if={@show_form} id="new-room-modal" show on_cancel={JS.push("hide-form")}>
      <.header>New chat room</.header>

      <.live_component
        module={SlaxWeb.ChatRoomLive.FormComponent}
        id="index"
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    rooms = Chat.list_rooms_with_membership(socket.assigns.current_user)

    socket =
      socket
      |> assign(show_form: false)
      |> stream_configure(:rooms, dom_id: fn {room, _} -> "rooms-#{room.id}" end)
      |> stream(:rooms, rooms)

    {:ok, socket}
  end

  @impl true
  def handle_event("hide-form", _params, socket) do
    {:noreply, assign(socket, show_form: false)}
  end

  @impl true
  def handle_event("show-form", _params, socket) do
    {:noreply, assign(socket, show_form: true)}
  end

  @impl true
  def handle_event("toggle-room-membership", %{"id" => id}, socket) do
    id
    |> Chat.get_room!()
    |> Chat.toggle_room_membership(socket.assigns.current_user)

    {:noreply,
     stream(socket, :rooms, Chat.list_rooms_with_membership(socket.assigns.current_user))}
  end

  @impl true
  def handle_event("view-room", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/rooms/#{id}")}
  end

  @impl true
  def handle_info({SlaxWeb.ChatRoomLive.FormComponent, {:created, room}}, socket) do
    Chat.join_room(room, socket.assigns.current_user)

    {:noreply,
     socket
     |> put_flash(:info, "Created room")
     |> push_navigate(to: ~p"/rooms/#{room}")}
  end
end
