[email | _] = System.argv()

alias Fantasy.{Repo, Accounts.User}

case Repo.get_by(User, name: email) do
  nil ->
    IO.puts("User with email #{email} not found.")
    System.halt(1)

  user ->
    user
    |> Ecto.Changeset.change(is_admin: true)
    |> Repo.update!()

    IO.puts("#{email} is now an admin.")
end
