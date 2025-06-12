defmodule SlaxWeb.ChatRoomLive.ProfileComponent do
  use SlaxWeb, :live_component

  import SlaxWeb.UserComponents

  def render(assigns) do
    ~H"""
    <div class="flex flex-col shrink-0 w-1/4 max-w-xs bg-white shadow-xl">
      <div class="flex items-center h-16 border-b border-slate-300 px-4">
        <div class="">
          <h2 class="text-lg font-bold text-gray-800">
            Profile
          </h2>
        </div>
        <button
          class="flex items-center justify-center w-6 h-6 rounded hover:bg-gray-300 ml-auto"
          phx-click="close-profile"
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>
      <div class="flex flex-col grow overflow-auto p-4">
        <div class="mb-4">
          <.user_avatar user={@user} class="w-48 rounded mx-auto" />
        </div>
        <h2 class="text-xl font-bold text-gray-800">
          {@user.username}
        </h2>
      </div>
    </div>
    """
  end
end
