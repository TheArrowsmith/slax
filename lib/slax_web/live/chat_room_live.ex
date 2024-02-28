defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.Accounts
  alias Slax.Accounts.User
  alias Slax.Chat
  alias Slax.Chat.{Message, Room}
  alias SlaxWeb.OnlineUsers

  @impl true
  def mount(_params, _session, socket) do
    rooms = Chat.list_joined_rooms(socket.assigns.current_user)
    users = Accounts.list_users()

    OnlineUsers.track(self(), socket.assigns.current_user)
    OnlineUsers.subscribe()

    rooms |> Enum.map(&elem(&1, 0)) |> Chat.subscribe_to_rooms()

    socket =
      socket
      |> assign_message_form(%Message{})
      |> assign(rooms: rooms, users: users)
      |> assign(:online_users, OnlineUsers.list())
      |> stream_configure(:messages,
        dom_id: fn
          %Message{id: id} -> "messages-#{id}"
          :unread_marker -> "messages-unread-marker"
          %Date{} = date -> to_string(date)
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
    last_read_id = Chat.get_last_read_id(room, socket.assigns.current_user)

    messages =
      room
      |> Chat.list_messages_in_room()
      |> insert_date_markers()
      |> maybe_insert_unread_marker(last_read_id)

    Chat.update_last_read_id(room, socket.assigns.current_user)

    socket
    |> assign(room: room, joined?: Chat.joined?(room, socket.assigns.current_user))
    |> scroll_messages_to_bottom()
    |> stream(:messages, messages, reset: true)
    |> update(:rooms, fn rooms ->
      room_id = room.id

      Enum.map(rooms, fn
        {%Room{id: ^room_id} = room, _} -> {room, 0}
        other -> other
      end)
    end)
  end

  defp insert_date_markers(messages) do
    messages
    |> Enum.group_by(&NaiveDateTime.to_date(&1.inserted_at))
    |> Enum.flat_map(fn {date, messages} -> [date | messages] end)
  end

  defp maybe_insert_unread_marker(messages, nil), do: messages

  defp maybe_insert_unread_marker(messages, last_read_id) do
    {read, unread} =
      Enum.split_while(messages, fn
        %Message{} = message -> message.id <= last_read_id
        _ -> true
      end)

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
  def handle_event("show-new-room-modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/rooms/#{socket.assigns.room}/new")}
  end

  @impl true
  def handle_event("submit-message", %{"message" => message_params}, socket) do
    socket = maybe_submit_message(socket, message_params, socket.assigns.joined?)
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate-message", %{"message" => message_params}, socket) do
    message = Chat.change_message(%Message{}, message_params)

    {:noreply, assign_message_form(socket, message)}
  end

  def assign_message_form(socket, message) do
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
          assign_message_form(socket, %Message{})

        {:error, _changeset} ->
          socket
      end

    socket
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    %{room: room} = socket.assigns

    socket =
      cond do
        message.room_id == room.id ->
          Chat.update_last_read_id(room, socket.assigns.current_user)

          socket
          |> stream_insert(:messages, message)
          |> scroll_messages_to_bottom()

        message.user_id != socket.assigns.current_user.id ->
          message_room_id = message.room_id

          update(socket, :rooms, fn rooms ->
            Enum.map(rooms, fn
              {%Room{id: id} = room, count} when id == message_room_id -> {room, count + 1}
              other -> other
            end)
          end)

        true ->
          socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_deleted, message}, socket) do
    {:noreply, stream_delete(socket, :messages, message)}
  end

  @impl true
  def handle_info({:room_created, room}, socket) do
    Chat.join_room(room, socket.assigns.current_user)

    {:noreply,
     socket
     |> put_flash(:info, "Created room")
     |> update(:rooms, &([{room, 0} | &1] |> Enum.sort_by(fn {r, _} -> r.name end)))
     |> push_patch(to: ~p"/rooms/#{room}")}
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

  def message_or_divider(%{message: :unread_marker} = assigns) do
    ~H"""
    <.unread_messages_divider html_id={@html_id} />
    """
  end

  def message_or_divider(%{message: %Date{}} = assigns) do
    ~H"""
    <.date_divider html_id={@html_id} date={@message} />
    """
  end

  def message_or_divider(%{message: %Message{}} = assigns) do
    ~H"""
    <.message html_id={@html_id} message={@message} current_user={@current_user} />
    """
  end

  defp date_divider(assigns) do
    ~H"""
    <div id={@html_id} class="flex flex-col items-center mt-2">
      <hr class="w-full" />
      <span class="flex items-center justify-center -mt-3 bg-white h-6 px-3 rounded-full border text-xs font-semibold mx-auto">
        <%= format_date(@date) %>
      </span>
    </div>
    """
  end

  defp format_date(%Date{} = date) do
    today = Date.utc_today()

    case Date.diff(today, date) do
      0 ->
        "Today"

      1 ->
        "Yesterday"

      _ ->
        format_str = "%A, %B %e#{ordinal(date.day)}#{if today.year != date.year, do: " %Y"}"
        Timex.format!(date, format_str, :strftime)
    end
  end

  defp ordinal(day) do
    cond do
      rem(day, 10) == 1 and day != 11 -> "st"
      rem(day, 10) == 2 and day != 12 -> "nd"
      rem(day, 10) == 3 and day != 13 -> "rd"
      true -> "th"
    end
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

  attr :count, :integer, required: true

  defp unread_message_counter(assigns) do
    ~H"""
    <span
      :if={@count > 0}
      class="flex items-center justify-center bg-blue-500 rounded-full font-medium h-5 px-2 ml-auto text-xs text-white"
    >
      <%= @count %>
    </span>
    """
  end

  defp message_timestamp(message) do
    Timex.format!(message.inserted_at, "%-l:%M %p", :strftime)
  end

  defp scroll_messages_to_bottom(socket) do
    push_event(socket, "scroll_messages_to_bottom", %{})
  end
end
