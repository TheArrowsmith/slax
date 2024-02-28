defmodule SlaxWeb.ChatRoomLive.ProfileComponent do
  use SlaxWeb, :live_component

  alias Slax.Accounts

  @impl true
  def mount(socket) do
    {:ok, allow_upload(socket, :avatar, accept: ~w(.png .jpg), max_entries: 1)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(avatar_form: to_form(%{}))

    {:ok, socket}
  end

  @impl true
  def handle_event("submit-avatar", _, socket) do
    if socket.assigns.user != socket.assigns.current_user do
      raise "Prohibited"
    end

    avatar_path =
      socket
      |> consume_uploaded_entries(:avatar, fn upload = %{path: path}, entry ->
        dest = Path.join("priv/static/uploads", Path.basename(path))
        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)
      |> List.first()

    {:ok, user} = Accounts.save_user_avatar_path(socket.assigns.current_user, avatar_path)

    {:noreply, assign(socket, :user, user)}
  end

  @impl true
  def handle_event("validate-avatar", _, socket), do: {:noreply, socket}
end
