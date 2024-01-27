defmodule SlaxWeb.OnlineUsers do
  alias SlaxWeb.Endpoint
  alias SlaxWeb.Presence

  @topic "online_users"

  def subscribe() do
    Endpoint.subscribe(@topic)
  end

  def track(pid, user) do
    {:ok, _} = Presence.track(pid, @topic, user.id, %{})
    :ok
  end

  def list() do
    @topic
    |> Presence.list()
    |> extract_user_ids_as_mapset()
  end

  def update(current, %{joins: joined, leaves: left}) do
    current
    |> MapSet.union(extract_user_ids_as_mapset(joined))
    |> MapSet.difference(extract_user_ids_as_mapset(left))
  end

  defp extract_user_ids_as_mapset(map) do
    map
    |> Map.keys()
    |> Enum.map(&String.to_integer/1)
    |> Enum.into(MapSet.new())
  end
end
