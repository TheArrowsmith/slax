defmodule SlaxWeb.ChatRoomLive.Edit do
  use SlaxWeb, :live_view

  alias Slax.Chat

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto w-72 mt-12">
      <.header>Edit chat room</.header>

      <.link
        class="font-normal text-xs text-blue-600 hover:text-blue-700"
        navigate={~p"/rooms/#{@room}"}
      >
        Back
      </.link>

      <.simple_form for={@form} id="room-form" phx-change="validate-room" phx-submit="save-room">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:topic]} type="text" label="Topic" />
        <:actions>
          <.button phx-disable-with="Saving..." class="w-full">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    room = Chat.get_room!(id)

    socket =
      if Chat.joined?(room, socket.assigns.current_user) do
        changeset = Chat.change_room(room)
        socket |> assign(room: room) |> assign_form(changeset)
      else
        socket
        |> put_flash(:error, "Permission denied")
        |> push_navigate(to: ~p"/")
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("validate-room", %{"room" => room_params}, socket) do
    changeset =
      socket.assigns.room
      |> Chat.change_room(room_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save-room", %{"room" => room_params}, socket) do
    case Chat.update_room(socket.assigns.room, room_params) do
      {:ok, room} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room updated successfully")
         |> push_navigate(to: ~p"/rooms/#{room}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
