defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.Accounts
  alias Slax.Accounts.User
  alias Slax.Chat
  alias Slax.Chat.Message
  alias Slax.Chat.Room
  alias SlaxWeb.OnlineUsers

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
        <.toggler on_click={toggle_rooms()} dom_id="rooms-toggler" text="Rooms" />
        <div id="rooms-list">
          <.room_link :for={room <- @rooms} room={room} active={room.id == @room.id} />

          <div class="relative">
            <button
              class="flex items-center peer h-8 text-sm pl-8 pr-3 hover:bg-slate-300 cursor-pointer w-full"
              phx-click={JS.toggle(to: "#sidebar-rooms-menu")}
            >
              <.icon name="hero-plus" class="h-4 w-4 relative top-px" />
              <span class="ml-2 leading-none">Add rooms</span>
            </button>

            <div
              id="sidebar-rooms-menu"
              class="hidden cursor-default absolute top-8 right-2 bg-white border-slate-200 border py-3 rounded-lg"
              phx-click-away={JS.hide()}
            >
              <div class="w-full text-left">
                <.link
                  class="block select-none cursor-pointer whitespace-nowrap text-gray-800 hover:text-white px-6 py-1 block hover:bg-sky-600"
                  navigate={~p"/rooms"}
                >
                  Browse rooms
                </.link>
              </div>
            </div>
          </div>
        </div>
        <div class="mt-4">
          <.toggler on_click={toggle_users()} dom_id="users-toggler" text="Users" />
          <div id="users-list">
            <.user
              :for={user <- @users}
              online={OnlineUsers.online?(@online_users, user.id)}
              user={user}
            />
          </div>
        </div>
      </div>
    </div>
    <div class="flex flex-col grow shadow-lg">
      <div class="flex justify-between items-center shrink-0 h-16 bg-white border-b border-slate-300 px-4">
        <div class="flex flex-col gap-1.5">
          <h1 class="text-sm font-bold leading-none">
            #{@room.name}

            <.link
              :if={@joined?}
              class="font-normal text-xs text-blue-600 hover:text-blue-700"
              navigate={~p"/rooms/#{@room}/edit"}
            >
              Edit
            </.link>
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
        <ul class="relative z-10 flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end">
          <li class="text-[0.8125rem] leading-6 text-zinc-900">
            {username(@current_user)}
          </li>
          <li>
            <.link
              href={~p"/users/settings"}
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              Settings
            </.link>
          </li>
          <li>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              Log out
            </.link>
          </li>
        </ul>
      </div>
      <div
        id="room-messages"
        class="flex flex-col grow overflow-auto"
        phx-hook="RoomMessages"
        phx-update="stream"
      >
        <.message
          :for={{dom_id, message} <- @streams.messages}
          current_user={@current_user}
          dom_id={dom_id}
          message={message}
          timezone={@timezone}
        />
      </div>
      <div :if={@joined?} class="h-12 bg-white px-4 pb-4">
        <.form
          id="new-message-form"
          for={@new_message_form}
          phx-change="validate-message"
          phx-submit="submit-message"
          class="flex items-center border-2 border-slate-300 rounded-sm p-1 border-b-0"
        >
          <textarea
            class="grow text-sm px-3 border-l border-slate-300 mx-1 resize-none"
            cols=""
            id="chat-message-textarea"
            name={@new_message_form[:body].name}
            placeholder={"Message ##{@room.name}"}
            phx-debounce
            phx-hook="ChatMessageTextarea"
            rows="1"
          >{Phoenix.HTML.Form.normalize_value("textarea", @new_message_form[:body].value)}</textarea>
          <button class="shrink flex items-center justify-center h-6 w-6 rounded hover:bg-slate-200">
            <.icon name="hero-paper-airplane" class="h-4 w-4" />
          </button>
        </.form>
      </div>
      <div
        :if={!@joined?}
        class="flex justify-around mx-5 mb-5 p-6 bg-slate-100 border-slate-300 border rounded-lg"
      >
        <div class="max-w-3-xl text-center">
          <div class="mb-4">
            <h1 class="text-xl font-semibold">#{@room.name}</h1>
            <p :if={@room.topic} class="text-sm mt-1 text-gray-600">{@room.topic}</p>
          </div>
          <div class="flex items-center justify-around">
            <button
              phx-click="join-room"
              class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-green-500"
            >
              Join Room
            </button>
          </div>
          <div class="mt-4">
            <.link
              navigate={~p"/rooms"}
              href="#"
              class="text-sm text-slate-500 underline hover:text-slate-600"
            >
              Back to All Rooms
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :dom_id, :string, required: true
  attr :on_click, JS, required: true
  attr :text, :string, required: true

  defp toggler(assigns) do
    ~H"""
    <div class="flex items-center h-8 px-3">
      <button id={@dom_id} phx-click={@on_click} class="flex items-center grow">
        <.icon id={@dom_id <> "-chevron-down"} name="hero-chevron-down" class="h-4 w-4" />
        <.icon
          id={@dom_id <> "-chevron-right"}
          name="hero-chevron-right"
          class="h-4 w-4"
          style="display:none;"
        />
        <span class="ml-2 leading-none font-medium text-sm">
          {@text}
        </span>
      </button>
    </div>
    """
  end

  attr :current_user, User, required: true
  attr :dom_id, :string, required: true
  attr :message, Message, required: true
  attr :timezone, :string, required: true

  defp message(assigns) do
    ~H"""
    <div id={@dom_id} class="group relative flex px-4 py-3">
      <button
        :if={@current_user.id == @message.user_id}
        data-confirm="Are you sure?"
        phx-click="delete-message"
        phx-value-id={@message.id}
        class="absolute top-4 right-4 text-red-500 hover:text-red-800 cursor-pointer hidden group-hover:block"
      >
        <.icon name="hero-trash" class="h-4 w-4" />
      </button>
      <div class="h-10 w-10 rounded shrink-0 bg-slate-300"></div>
      <div class="ml-2">
        <div class="-mt-1">
          <.link class="text-sm font-semibold hover:underline">
            <span>{username(@message.user)}</span>
          </.link>
          <span :if={@timezone} class="ml-1 text-xs text-gray-500">
            {message_timestamp(@message, @timezone)}
          </span>
          <p class="text-sm">{@message.body}</p>
        </div>
      </div>
    </div>
    """
  end

  attr :user, User, required: true
  attr :online, :boolean, default: false

  defp user(assigns) do
    ~H"""
    <.link class="flex items-center h-8 hover:bg-gray-300 text-sm pl-8 pr-3" href="#">
      <div class="flex justify-center w-4">
        <%= if @online do %>
          <span class="w-2 h-2 rounded-full bg-blue-500"></span>
        <% else %>
          <span class="w-2 h-2 rounded-full border-2 border-gray-500"></span>
        <% end %>
      </div>
      <span class="ml-2 leading-none">{username(@user)}</span>
    </.link>
    """
  end

  defp username(user) do
    user.email |> String.split("@") |> List.first() |> String.capitalize()
  end

  defp message_timestamp(message, timezone) do
    message.inserted_at
    |> Timex.Timezone.convert(timezone)
    |> Timex.format!("%-l:%M %p", :strftime)
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
    rooms = Chat.list_joined_rooms(socket.assigns.current_user)
    users = Accounts.list_users()

    timezone = get_connect_params(socket)["timezone"]

    if connected?(socket) do
      OnlineUsers.track(self(), socket.assigns.current_user)
    end

    OnlineUsers.subscribe()

    socket =
      socket
      |> assign(rooms: rooms, timezone: timezone, users: users)
      |> assign(online_users: OnlineUsers.list())

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    if socket.assigns[:room], do: Chat.unsubscribe_from_room(socket.assigns.room)

    room = params |> Map.fetch!("id") |> Chat.get_room!()
    messages = Chat.list_messages_in_room(room)

    Chat.subscribe_to_room(room)

    {:noreply,
     socket
     |> assign(
       hide_topic?: false,
       joined?: Chat.joined?(room, socket.assigns.current_user),
       page_title: "#" <> room.name,
       room: room
     )
     |> stream(:messages, messages, reset: true)
     |> assign_message_form(Chat.change_message(%Message{}))
     |> push_event("scroll_messages_to_bottom", %{})}
  end

  defp assign_message_form(socket, changeset) do
    assign(socket, :new_message_form, to_form(changeset))
  end

  def handle_event("delete-message", %{"id" => id}, socket) do
    Chat.delete_message_by_id(id, socket.assigns.current_user)

    {:noreply, socket}
  end

  def handle_event("join-room", _, socket) do
    current_user = socket.assigns.current_user
    Chat.join_room!(socket.assigns.room, current_user)
    Chat.subscribe_to_room(socket.assigns.room)
    socket = assign(socket, joined?: true, rooms: Chat.list_joined_rooms(current_user))
    {:noreply, socket}
  end

  def handle_event("submit-message", %{"message" => message_params}, socket) do
    %{current_user: current_user, room: room} = socket.assigns

    socket =
      if Chat.joined?(room, current_user) do
        case Chat.create_message(room, message_params, current_user) do
          {:ok, _message} ->
            assign_message_form(socket, Chat.change_message(%Message{}))

          {:error, changeset} ->
            assign_message_form(socket, changeset)
        end
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("toggle-topic", _params, socket) do
    {:noreply, update(socket, :hide_topic?, &(!&1))}
  end

  def handle_event("validate-message", %{"message" => message_params}, socket) do
    changeset = Chat.change_message(%Message{}, message_params)

    {:noreply, assign_message_form(socket, changeset)}
  end

  def handle_info({:new_message, message}, socket) do
    socket =
      socket
      |> stream_insert(:messages, message)
      |> push_event("scroll_messages_to_bottom", %{})

    {:noreply, socket}
  end

  def handle_info({:message_deleted, message}, socket) do
    {:noreply, stream_delete(socket, :messages, message)}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    online_users = OnlineUsers.update(socket.assigns.online_users, diff)

    {:noreply, assign(socket, online_users: online_users)}
  end

  defp toggle_rooms do
    JS.toggle(to: "#rooms-toggler-chevron-down")
    |> JS.toggle(to: "#rooms-toggler-chevron-right")
    |> JS.toggle(to: "#rooms-list")
  end

  defp toggle_users do
    JS.toggle(to: "#users-toggler-chevron-down")
    |> JS.toggle(to: "#users-toggler-chevron-right")
    |> JS.toggle(to: "#users-list")
  end
end
