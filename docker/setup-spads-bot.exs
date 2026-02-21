alias Teiserver.{Account, Repo}

bot_name = System.get_env("SPADS_BOT_NAME", "spadsbot")

case Repo.get_by(Account.User, name: bot_name) do
  nil ->
    {:ok, user} =
      Account.create_user(%{
        name: bot_name,
        email: "#{bot_name}@spads.local",
        password: Account.spring_md5_password("password"),
        roles: ["Bot", "Verified", "Moderator"],
        permissions: ["Server"],
        icon: "fa-solid fa-robot",
        colour: "#AA0000",
        data: %{
          bot: true,
          lobby_client: "SPADS"
        }
      })

    IO.puts("Created SPADS bot account: #{user.name} (id: #{user.id})")

  user ->
    IO.puts("SPADS bot account already exists: #{user.name} (id: #{user.id})")
end
