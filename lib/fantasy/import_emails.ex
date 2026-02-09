defmodule Fantasy.ImportEmails do
  @moduledoc """
  One-time import of email addresses from Clerk CSV export.

  Maps Clerk user IDs to email addresses and updates existing users.
  Run via: mix run -e "Fantasy.ImportEmails.run()"
  Or in production: fly ssh console -C '/app/bin/fantasy eval "Fantasy.ImportEmails.run()"'
  """

  alias Fantasy.Repo

  def run do
    csv_path =
      Application.app_dir(:fantasy, "priv/repo/users.csv")

    IO.puts("Reading CSV from #{csv_path}")

    [_header | rows] =
      csv_path
      |> File.read!()
      |> String.split("\n", trim: true)

    updated =
      rows
      |> Enum.map(&parse_row/1)
      |> Enum.reject(fn {clerk_id, email} -> clerk_id == "" or email == "" end)
      |> Enum.count(fn {clerk_id, email} ->
        {count, _} =
          Repo.query!(
            ~s(UPDATE "User" SET email = ?1 WHERE "clerkId" = ?2 AND email IS NULL),
            [email, clerk_id]
          )
          |> then(fn %{num_rows: n} -> {n, nil} end)

        count > 0
      end)

    IO.puts("Updated #{updated} users with email addresses")
  end

  defp parse_row(row) do
    # CSV columns: id, first_name, last_name, username, primary_email_address, ...
    case String.split(row, ",", parts: 6) do
      [clerk_id, _, _, _, email | _] -> {clerk_id, email}
      _ -> {"", ""}
    end
  end
end
