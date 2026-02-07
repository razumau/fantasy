defmodule Fantasy.Repo.Migrations.MakeClerkIdNullable do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    Fantasy.Repo.checkout(fn ->
      Fantasy.Repo.query!("PRAGMA foreign_keys = OFF")

      Fantasy.Repo.query!("""
      CREATE TABLE "User_new" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "clerkId" TEXT,
        "name" TEXT NOT NULL,
        "isAdmin" BOOLEAN NOT NULL DEFAULT false,
        "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" DATETIME NOT NULL,
        "google_id" TEXT
      )
      """)

      Fantasy.Repo.query!(~s[INSERT INTO "User_new" SELECT * FROM "User"])
      Fantasy.Repo.query!(~s[DROP TABLE "User"])
      Fantasy.Repo.query!(~s[ALTER TABLE "User_new" RENAME TO "User"])

      Fantasy.Repo.query!(~s[CREATE UNIQUE INDEX "User_clerkId_key" ON "User"("clerkId")])
      Fantasy.Repo.query!(~s[CREATE UNIQUE INDEX "User_google_id_index" ON "User"("google_id")])

      Fantasy.Repo.query!("PRAGMA foreign_keys = ON")
    end)
  end

  def down do
    Fantasy.Repo.checkout(fn ->
      Fantasy.Repo.query!("PRAGMA foreign_keys = OFF")

      Fantasy.Repo.query!("""
      CREATE TABLE "User_new" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "clerkId" TEXT NOT NULL,
        "name" TEXT NOT NULL,
        "isAdmin" BOOLEAN NOT NULL DEFAULT false,
        "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" DATETIME NOT NULL,
        "google_id" TEXT
      )
      """)

      Fantasy.Repo.query!(~s[INSERT INTO "User_new" SELECT * FROM "User"])
      Fantasy.Repo.query!(~s[DROP TABLE "User"])
      Fantasy.Repo.query!(~s[ALTER TABLE "User_new" RENAME TO "User"])

      Fantasy.Repo.query!(~s[CREATE UNIQUE INDEX "User_clerkId_key" ON "User"("clerkId")])
      Fantasy.Repo.query!(~s[CREATE UNIQUE INDEX "User_google_id_index" ON "User"("google_id")])

      Fantasy.Repo.query!("PRAGMA foreign_keys = ON")
    end)
  end
end
