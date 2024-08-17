alias Slax.Accounts.User
alias Slax.Chat.Message
alias Slax.Chat.Room
alias Slax.Repo

room = Repo.insert!(%Room{name: "rohan"})
users = Repo.all(User)
now = DateTime.utc_now() |> DateTime.truncate(:second)

1..500
|> Enum.map(fn _ ->
  %Message{
    user: Enum.random(users),
    room: room,
    body: Faker.Lorem.Shakespeare.romeo_and_juliet(),
    inserted_at: DateTime.add(now, -:rand.uniform(365 * 24 * 60), :minute)
  }
end)
|> Enum.sort_by(& &1.inserted_at, &(DateTime.compare(&1, &2) != :gt))
|> Enum.each(fn m ->
  Repo.insert!(m)
end)
