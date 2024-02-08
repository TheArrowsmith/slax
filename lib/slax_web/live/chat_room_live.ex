defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.Accounts
  alias Slax.Accounts.User
  alias Slax.Chat
  alias Slax.Chat.Message
  alias SlaxWeb.OnlineUsers

  @impl true
  def mount(_params, _session, socket) do
    rooms = Chat.list_joined_rooms(socket.assigns.current_user)
    users = Accounts.list_users()

    OnlineUsers.track(self(), socket.assigns.current_user)
    OnlineUsers.subscribe()

    socket =
      socket
      |> assign_form(%Message{})
      |> assign(rooms: rooms, users: users)
      |> assign(:online_users, OnlineUsers.list())
      |> stream_configure(:messages,
        dom_id: fn
          %Message{id: id} -> "messages-#{id}"
          :unread_marker -> "messages-unread-marker"
        end
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _session, socket) do
    room =
      case params["id"] do
        nil ->
          Chat.get_first_room!()

        id ->
          Chat.get_room!(id)
      end

    {:noreply, maybe_update_room(socket, room)}
  end

  def maybe_update_room(%{assigns: %{room: %{id: id}}} = socket, %{id: id}) do
    socket
  end

  def maybe_update_room(socket, room) do
    Chat.subscribe_to_room(room)

    last_read_id = Chat.get_last_read_id(room, socket.assigns.current_user)

    messages =
      room
      |> Chat.list_messages_in_room()
      |> maybe_insert_unread_marker(last_read_id)

    Chat.update_last_read_id(room, socket.assigns.current_user)

    socket
    |> assign(room: room, joined?: Chat.joined?(room, socket.assigns.current_user))
    |> scroll_messages_to_bottom()
    |> stream(:messages, messages, reset: true)
  end

  defp maybe_insert_unread_marker(messages, nil), do: messages

  defp maybe_insert_unread_marker(messages, last_read_id) do
    {read, unread} = Enum.split_while(messages, &(&1.id <= last_read_id))

    if unread == [] do
      read
    else
      read ++ [:unread_marker | unread]
    end
  end

  @impl true
  def handle_event("browse-rooms", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/rooms")}
  end

  @impl true
  def handle_event("delete-message", %{"id" => id}, socket) do
    Chat.delete_message_by_id(id, socket.assigns.current_user)

    {:noreply, socket}
  end

  @impl true
  def handle_event("join-room", _, socket) do
    current_user = socket.assigns.current_user
    Chat.join_room(socket.assigns.room, current_user)
    socket = assign(socket, joined?: true, rooms: Chat.list_joined_rooms(current_user))
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit-message", %{"message" => message_params}, socket) do
    socket = maybe_submit_message(socket, message_params, socket.assigns.joined?)
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate-message", %{"message" => message_params}, socket) do
    message = Chat.change_message(%Message{}, message_params)

    {:noreply, assign_form(socket, message)}
  end

  def assign_form(socket, message) do
    form =
      message
      |> Chat.change_message()
      |> to_form()

    assign(socket, :new_message_form, form)
  end

  defp maybe_submit_message(socket, _, false), do: socket

  defp maybe_submit_message(socket, message_params, true) do
    %{current_user: current_user, room: room} = socket.assigns

    socket =
      case Chat.create_message(room, message_params, current_user) do
        {:ok, _message} ->
          assign_form(socket, %Message{})

        {:error, _changeset} ->
          socket
      end

    socket
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    %{room: room} = socket.assigns

    socket =
      if message.room_id == room.id do
        Chat.update_last_read_id(room, socket.assigns.current_user)

        socket
        |> stream_insert(:messages, message)
        |> scroll_messages_to_bottom()
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_deleted, message}, socket) do
    {:noreply, stream_delete(socket, :messages, message)}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    online_users = OnlineUsers.update(socket.assigns.online_users, diff)

    {:noreply, assign(socket, online_users: online_users)}
  end

  attr :current_user, User, required: true
  attr :html_id, :string, required: true
  attr :message, Message, required: true

  defp message(assigns) do
    ~H"""
    <div id={@html_id} class="relative group flex px-4 py-3">
      <button
        phx-click="delete-message"
        phx-value-id={@message.id}
        data-confirm="Are you sure?"
        class="absolute top-4 right-4 text-red-500 hover:text-red-800 cursor-pointer hidden group-hover:block"
      >
        <.icon :if={@current_user.id == @message.user.id} name="hero-trash" class="h-4 w-4" />
      </button>
      <div class="h-10 w-10 rounded flex-shrink-0 bg-slate-300"></div>
      <div class="ml-2">
        <div class="-mt-1">
          <span class="text-sm font-semibold"><%= @message.user.username %></span>
          <span class="ml-1 text-xs text-gray-500"><%= message_timestamp(@message) %></span>
        </div>
        <p class="text-sm"><%= @message.body %></p>
      </div>
    </div>
    """
  end

  attr :html_id, :string, required: true

  def unread_messages_divider(assigns) do
    ~H"""
    <div id={@html_id} class="w-full flex text-red-500 items-center gap-3 pr-5">
      <div class="w-full h-px grow bg-red-500"></div>
      <div class="text-sm">New</div>
    </div>
    """
  end

  attr :user, User, required: true
  attr :online, :boolean, default: false

  defp user_link(assigns) do
    ~H"""
    <.link class="flex items-center h-8 hover:bg-gray-300 text-sm pl-8 pr-3" href="#">
      <div class="flex justify-center w-4">
        <%= if @online do %>
          <span class="w-2 h-2 rounded-full bg-blue-500"></span>
        <% else %>
          <span class="w-2 h-2 rounded-full border-2 border-gray-500"></span>
        <% end %>
      </div>
      <span class={"ml-2 leading-none #{!@online && "text-gray-500"}"}><%= @user.username %></span>
    </.link>
    """
  end

  defp message_timestamp(message) do
    Timex.format!(message.inserted_at, "%-l:%M %p", :strftime)
  end

  defp scroll_messages_to_bottom(socket) do
    push_event(socket, "scroll_messages_to_bottom", %{})
  end
end
