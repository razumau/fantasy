defmodule Fantasy.Accounts.User do
  @moduledoc """
  User schema mapping to the existing Prisma User table.

  The table uses PascalCase naming from Prisma, and columns use camelCase.
  We use :source options to map Elixir snake_case to the existing column names.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "User" do
    field :clerk_id, :string, source: :clerkId
    field :google_id, :string
    field :name, :string
    field :email, :string
    field :is_admin, :boolean, default: false, source: :isAdmin
    field :created_at, Fantasy.Ecto.UnixTimestamp, source: :createdAt
    field :updated_at, Fantasy.Ecto.UnixTimestamp, source: :updatedAt

    has_many :picks, Fantasy.Tournaments.Pick, foreign_key: :userId
  end

  @doc """
  Changeset for creating a new user via Google OAuth.
  """
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:google_id, :name, :email])
    |> validate_required([:google_id, :name])
    |> unique_constraint(:google_id)
    |> unique_constraint(:email)
  end

  @doc """
  Changeset for updating user information.
  """
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:google_id, :name, :email, :is_admin])
    |> validate_required([:name])
    |> unique_constraint(:google_id)
    |> unique_constraint(:email)
  end

  @doc """
  Changeset for linking a Google account to an existing user.
  Used during migration from Clerk to Google OAuth.
  """
  def link_google_changeset(user, attrs) do
    user
    |> cast(attrs, [:google_id, :name, :email])
    |> validate_required([:google_id])
    |> unique_constraint(:google_id)
    |> unique_constraint(:email)
  end
end
