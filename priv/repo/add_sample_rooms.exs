alias Slax.Chat

for _ <- 1..50 do
  name =
    Enum.map(
      1..3,
      fn _ -> Faker.Lorem.word() |> String.downcase() end
    ) |> Enum.join("-" )

  {:ok, _room} = Chat.create_room(%{name: name})
end
