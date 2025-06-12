defmodule SlaxWeb.ChatComponents do
  use SlaxWeb, :html

  alias Slax.Accounts.User
  alias Slax.Chat.Message

  import SlaxWeb.UserComponents

  attr :current_user, User, required: true
  attr :dom_id, :string, required: true
  attr :message, :any, required: true
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
          phx-click={
            JS.dispatch(
              "show_emoji_picker",
              detail: %{message_id: @message.id}
            )
          }
          class="reaction-menu-button text-slate-500 hover:text-slate-600 cursor-pointer"
        >
          <.icon name="hero-face-smile" class="h-5 w-5" />
        </button>

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
          phx-value-type={@message.__struct__ |> Module.split() |> List.last()}
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
          <div
            :if={is_struct(@message, Message) && Enum.any?(@message.reactions)}
            class="flex space-x-2 mt-2"
          >
            <%= for {emoji, count, me?} <- enumerate_reactions(@message.reactions, @current_user) do %>
              <button
                class={[
                  "flex items-center pl-2 pr-2 h-6 rounded-full text-xs",
                  me? && "bg-blue-100 border border-blue-400",
                  !me? && "bg-slate-200 hover:bg-slate-400"
                ]}
                phx-click={if me?, do: "remove-reaction", else: "add-reaction"}
                phx-value-emoji={emoji}
                phx-value-message_id={@message.id}
              >
                <span>{emoji}</span>
                <span class="ml-1 font-medium">{count}</span>
              </button>
            <% end %>
          </div>
          <div
            :if={!@in_thread? && Enum.any?(@message.replies)}
            class="inline-flex items-center mt-2 rounded border border-transparent hover:border-slate-200 hover:bg-slate-50 py-1 pr-2 box-border cursor-pointer"
            phx-click="show-thread"
            phx-value-id={@message.id}
          >
            <.thread_avatars replies={@message.replies} />
            <a class="inline-block text-blue-600 text-xs font-medium ml-1" href="#">
              {length(@message.replies)}
              <%= if length(@message.replies) == 1 do %>
                reply
              <% else %>
                replies
              <% end %>
            </a>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp enumerate_reactions(reactions, current_user) do
    reactions
    |> Enum.group_by(& &1.emoji)
    |> Enum.map(fn {emoji, reactions} ->
      me? = Enum.any?(reactions, &(&1.user_id == current_user.id))

      {emoji, length(reactions), me?}
    end)
  end

  defp thread_avatars(assigns) do
    users =
      assigns.replies
      |> Enum.map(& &1.user)
      |> Enum.uniq_by(& &1.id)

    assigns = assign(assigns, :users, users)

    ~H"""
    <.user_avatar :for={user <- @users} class="h-6 w-6 rounded shrink-0 ml-1" user={user} />
    """
  end

  defp message_timestamp(message, timezone) do
    message.inserted_at
    |> Timex.Timezone.convert(timezone)
    |> Timex.format!("%-l:%M %p", :strftime)
  end
end
