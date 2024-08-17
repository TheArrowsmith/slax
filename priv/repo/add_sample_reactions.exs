alias Slax.Accounts.User
alias Slax.Chat
alias Slax.Chat.Room
alias Slax.Repo

emojis = [
  "😁","😃","🔥","👍","👎","❤️","😘","🤨","👌","👏","✅","😢","☹️",
]


room = Room |> Repo.get_by!(name: "council-of-elrond") |> Repo.preload(:messages)

users = Repo.all(User)

for message <- room.messages do
  num_reactions = :rand.uniform(5) - 1

  if num_reactions > 0 do
    for _ <- (0..num_reactions) do
      Chat.add_reaction(
        Enum.random(emojis),
        message,
        Enum.random(users)
      )
    end
  end
end
