defmodule SlaxWeb.ChatRoomLive.FormComponent do
  use SlaxWeb, :live_component

  alias Slax.Chat
  alias Slax.Chat.Room

  import SlaxWeb.RoomComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div id="new-room-form">
      <.room_form form={@form} target={@myself} />
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset = Chat.change_room(%Room{})
    assign_form(socket, changeset)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def handle_event("save-room", %{"room" => room_params}, socket) do
    case Chat.create_room(room_params) do
      {:ok, room} ->
        send(self(), {:room_created, room})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("validate-room", %{"room" => room_params}, socket) do
    changeset =
      %Room{}
      |> Chat.change_room(room_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end
end
