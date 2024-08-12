alias Slax.Accounts.User
alias Slax.Chat.Reply
alias Slax.Chat.Room
alias Slax.Repo

room = Room |> Repo.get_by!(name: "council-of-elrond") |> Repo.preload(:messages)

users = Repo.all(User)

now = DateTime.utc_now() |> DateTime.truncate(:second)

for message <- room.messages do
  num_replies = :rand.uniform(4) - 1

  if num_replies > 0 do
    for _ <- (0..num_replies) do
      Repo.insert!(
        %Reply{
          user: Enum.random(users),
          message: message,
          body: Faker.Lorem.Shakespeare.hamlet(),
          inserted_at: DateTime.add(now, :rand.uniform(10), :minute)

        }
      )
    end
  end
end
