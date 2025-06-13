defmodule SlaxWeb.ChatRoomLive.ThreadComponent do
  use SlaxWeb, :live_component

  import SlaxWeb.ChatComponents

  def render(assigns) do
    ~H"""
    <div class="flex flex-col shrink-0 w-1/4 max-w-xs border-l border-slate-300 bg-slate-100">
      <div class="flex items-center shrink-0 h-16 border-b border-slate-300 px-4">
        <div>
          <h2 class="text-sm font-semibold leading-none">Thread</h2>
          <a class="text-xs leading-none" href="#">#{@room.name}</a>
        </div>
        <button
          class="flex items-center justify-center w-6 h-6 rounded hover:bg-gray-300 ml-auto"
          phx-click="close-thread"
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>
      <div class="flex flex-col grow overflow-auto">
        <div class="border-b border-slate-300">
          <.message
            message={@message}
            dom_id="thread-message"
            current_user={@current_user}
            in_thread?
            timezone={@timezone}
          />
        </div>
      </div>
    </div>
    """
  end
end
