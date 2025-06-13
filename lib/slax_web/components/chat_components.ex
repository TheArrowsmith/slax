defmodule SlaxWeb.ChatComponents do
  use SlaxWeb, :html

  alias Slax.Accounts.User
  alias Slax.Chat.Message

  import SlaxWeb.UserComponents

  attr :current_user, User, required: true
  attr :dom_id, :string, required: true
  attr :message, Message, required: true
  attr :in_thread?, :boolean, default: false
  attr :timezone, :string, required: true

  def message(assigns) do
    ~H"""
    <div id={@dom_id} class="group relative flex px-4 py-3">
      <div
        :if={!@in_thread? || @current_user.id == @message.user_id}
        class="absolute top-4 right-4 opacity-0 group-hover:opacity-100 focus-within:opacity-100 bg-white shadow-sm px-2 pb-1 rounded border border-px border-slate-300 gap-1"
      >
        <button
          :if={!@in_thread?}
          phx-click="show-thread"
          phx-value-id={@message.id}
          class="text-slate-500 hover:text-slate-600 cursor-pointer"
        >
          <.icon name="hero-chat-bubble-bottom-center-text" class="h-4 w-4" />
        </button>

        <button
          :if={@current_user.id == @message.user_id}
          class="text-red-500 hover:text-red-800 cursor-pointer"
          data-confirm="Are you sure?"
          phx-click="delete-message"
          phx-value-id={@message.id}
        >
          <.icon name="hero-trash" class="h-4 w-4" />
        </button>
      </div>

      <.user_avatar
        user={@message.user}
        class="h-10 w-10 rounded cursor-pointer"
        phx-click="show-profile"
        phx-value-user-id={@message.user.id}
      />
      <div class="ml-2">
        <div class="-mt-1">
          <.link
            phx-click="show-profile"
            phx-value-user-id={@message.user.id}
            class="text-sm font-semibold hover:underline"
          >
            {@message.user.username}
          </.link>
          <span :if={@timezone} class="ml-1 text-xs text-gray-500">
            {message_timestamp(@message, @timezone)}
          </span>
          <p class="text-sm">{@message.body}</p>
        </div>
      </div>
    </div>
    """
  end

  defp message_timestamp(message, timezone) do
    message.inserted_at
    |> Timex.Timezone.convert(timezone)
    |> Timex.format!("%-l:%M %p", :strftime)
  end
end
