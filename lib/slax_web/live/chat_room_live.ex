defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.Accounts.User
  alias Slax.Chat
  alias Slax.Chat.Message

  @impl true
  def mount(_params, _session, socket) do
    rooms = Chat.list_rooms()

    socket =
      socket
      |> assign_form(%Message{})
      |> assign(rooms: rooms)

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
    socket
    |> assign(room: room)
    |> stream(:messages, Chat.list_messages_in_room(room), reset: true)
  end

  @impl true
  def handle_event("delete-message", %{"id" => id}, socket) do
    {:ok, message} = Chat.delete_message_by_id(id, socket.assigns.current_user)

    {:noreply, stream_delete(socket, :messages, message)}
  end

  @impl true
  def handle_event("submit-message", %{"message" => message_params}, socket) do
    %{current_user: current_user, room: room} = socket.assigns

    socket =
      case Chat.create_message(room, message_params, current_user) do
        {:ok, message} ->
          socket
          |> assign_form(%Message{})
          |> stream_insert(:messages, message)

        {:error, _changeset} ->
          socket
      end

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

  defp message_timestamp(message) do
    Timex.format!(message.inserted_at, "%-l:%M %p", :strftime)
  end
end
