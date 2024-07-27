alias Slax.Accounts.User
alias Slax.Chat.Message
alias Slax.Chat.Room
alias Slax.Repo

room = Repo.insert!(%Room{name: "mordor"})
users = Repo.all(User)
now = DateTime.utc_now() |> DateTime.truncate(:second)

for _ <- 1..40 do
  %Message{
    user: Enum.random(users),
    room: room,
    body: Faker.Lorem.Shakespeare.king_richard_iii(),
    inserted_at: DateTime.add(now, -:rand.uniform(10 * 24 * 60), :minute)
  }
end
|> Enum.sort_by(& &1.inserted_at, &(DateTime.compare(&1, &2) != :gt))
|> Enum.each(&Repo.insert!/1)
