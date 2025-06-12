alias Slax.Accounts.User
alias Slax.Chat.Message
alias Slax.Chat.Room
alias Slax.Repo

room =
  case Repo.get_by(Room, name: "mordor") do
    %Room{} = mordor ->
      mordor

    nil ->
      Repo.insert!(%Room{name: "mordor"})
  end

now = DateTime.utc_now() |> DateTime.truncate(:second)

users = Repo.all(User)

for _ <- 1..40 do
  %Message{
    user: Enum.random(users),
    room: room,
    body: Faker.Lorem.Shakespeare.king_richard_iii(),
    inserted_at: DateTime.add(now, -:rand.uniform(10 * 24 * 60), :minute)
  }
end
|> Enum.each(&Repo.insert!/1)
