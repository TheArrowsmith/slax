defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

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
    messages = Chat.list_messages_in_room(room)

    assign(socket, messages: messages, room: room)
  end

  @impl true
  def handle_event("submit-message", %{"message" => message_params}, socket) do
    %{current_user: current_user, room: room} = socket.assigns

    socket =
      case Chat.create_message(room, message_params, current_user) do
        {:ok, message} ->
          socket
          |> assign_form(%Message{})
          |> update(:messages, fn old -> old ++ [message] end)

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

  defp message_timestamp(message) do
    Timex.format!(message.inserted_at, "%-l:%M %p", :strftime)
  end
end
