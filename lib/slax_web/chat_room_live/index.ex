defmodule SlaxWeb.ChatRoomLive.Index do
  use SlaxWeb, :live_view

  alias Slax.Chat

  def render(assigns) do
    ~H"""
    <main class="flex-1 p-6 max-w-4xl mx-auto">
      <div class="flex justify-between mb-4 items-center">
        <h1 class="text-xl font-semibold">{@page_title}</h1>
        <h1 class="text-xl font-semibold">{@page_title}</h1>
        <button
          phx-click={show_modal("new-room-modal")}
          class="bg-white font-semibold py-2 px-4 border border-slate-400 rounded shadow-sm"
        >
          Create room
        </button>
      </div>
      <div class="bg-slate-50 border rounded">
        <div id="rooms" class="divide-y" phx-update="stream">
          <div
            :for={{id, {room, joined?}} <- @streams.rooms}
            class="cursor-pointer p-4 flex justify-between items-center group first:rounded-t last:rounded-b"
            id={id}
            phx-click={open_room(room)}
            phx-keydown={open_room(room)}
            phx-key="Enter"
            tabindex="0"
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

            <button
              class="opacity-0 group-hover:opacity-100 group-focus:opacity-100 focus:opacity-100 bg-white hover:bg-gray-100 border border-gray-400 text-gray-700 px-3 py-1.5 w-24 rounded-sm font-bold"
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

      <div :if={@num_pages > 1} class="py-4">
        <nav class="flex justify-around">
          <ul class="flex items-center -space-x-px h-10 text-base">
            <li>
              <.link
                patch={
                  if @page == 1 do
                    ""
                  else
                    ~p"/rooms?page=#{@page - 1}"
                  end
                }
                class="flex items-center justify-center px-4 h-10 ms-0 leading-tight text-gray-500 bg-white border border-e-0 border-gray-300 rounded-s-lg hover:bg-gray-100 hover:text-gray-700"
              >
                <span class="sr-only">Previous</span> &lsaquo;
              </.link>
            </li>
            <.page_number :for={i <- 1..@num_pages} number={i} current?={i == @page} />
            <li>
              <.link
                patch={
                  if @page + 1 > @num_pages do
                    ""
                  else
                    ~p"/rooms?page=#{@page + 1}"
                  end
                }
                class="flex items-center justify-center px-4 h-10 leading-tight text-gray-500 bg-white border border-gray-300 rounded-e-lg hover:bg-gray-100 hover:text-gray-700"
              >
                <span class="sr-only">Next</span> &rsaquo;
              </.link>
            </li>
          </ul>
        </nav>
      </div>
    </main>

    <.modal id="new-room-modal">
      <.header>New chat room</.header>

      <.live_component
        module={SlaxWeb.ChatRoomLive.FormComponent}
        id="new-room-form-component"
        current_user={@current_user}
      />
    </.modal>
    """
  end

  defp open_room(room) do
    JS.navigate(~p"/rooms/#{room}")
  end

  attr :number, :any, required: true
  attr :current?, :boolean, default: false

  defp page_number(assigns) do
    ~H"""
    <li>
      <.link
        patch={~p"/rooms?page=#{@number}"}
        class={[
          "flex items-center justify-center px-4 h-10 leading-tight",
          if @current? do
            "text-blue-600 border border-blue-300 bg-blue-50 hover:bg-blue-100 hover:text-blue-700"
          else
            "text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700"
          end
        ]}
      >
        {@number}
      </.link>
    </li>
    """
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(num_pages: Chat.count_room_pages())
    |> assign(:page_title, "All rooms")
    |> stream_configure(:rooms, dom_id: fn {room, _} -> "rooms-#{room.id}" end)
    |> ok()
  end

  def handle_params(params, _uri, socket) do
    page = params |> Map.get("page", "1") |> String.to_integer()

    rooms = Chat.list_rooms_with_joined(page, socket.assigns.current_user)

    socket
    |> assign(page: page)
    |> stream(:rooms, rooms, reset: true)
    |> noreply()
  end

  def handle_event("toggle-room-membership", %{"id" => id}, socket) do
    {room, joined?} =
      id
      |> Chat.get_room!()
      |> Chat.toggle_room_membership(socket.assigns.current_user)

    socket
    |> stream_insert(:rooms, {room, joined?})
    |> noreply()
  end
end
