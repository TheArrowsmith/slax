defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.Chat
  alias Slax.Chat.Message

  @impl true
  def mount(_params, _session, socket) do
    room = Chat.get_first_room!()
    messages = Chat.list_messages_in_room(room)

    socket =
      socket
      |> assign_form(%Message{})
      |> assign(messages: messages, room: room)

    {:ok, socket}
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
