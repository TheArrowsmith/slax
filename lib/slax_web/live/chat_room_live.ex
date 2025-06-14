defmodule SlaxWeb.ChatRoomLive do
  use SlaxWeb, :live_view

  alias Slax.Chat.Room
  alias Slax.Repo

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col grow shadow-lg">
        <div class="flex justify-between items-center shrink-0 h-16 bg-white border-b border-slate-300 px-4">
          <div class="flex flex-col gap-1.5">
            <h1 class="text-sm font-bold leading-none">
              #{@room.name}
            </h1>
            <div class="text-xs leading-none h-3.5">
              {@room.topic}
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    room = Room |> Repo.all() |> List.first()

    {:ok, assign(socket, :room, room)}
  end
end
