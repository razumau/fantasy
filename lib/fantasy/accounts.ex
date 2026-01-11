defmodule Fantasy.Accounts do
  @moduledoc """
  The Accounts context handles user management and authentication.
  """

  alias Fantasy.Repo
  alias Fantasy.Accounts.User

  @doc """
  Gets a single user by ID.

  Returns nil if the user does not exist.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Gets a single user by ID.

  Raises `Ecto.NoResultsError` if the user does not exist.
  """
  def get_user!(id) do
    Repo.get!(User, id)
  end

  @doc """
  Gets a user by their Google ID.

  Returns nil if no user is found with that Google ID.
  """
  def get_user_by_google_id(google_id) when is_binary(google_id) do
    Repo.get_by(User, google_id: google_id)
  end

  def get_user_by_google_id(_), do: nil

  @doc """
  Gets a user by their name (email).

  Used for matching existing users during migration from Clerk.
  """
  def get_user_by_name(name) when is_binary(name) do
    Repo.get_by(User, name: name)
  end

  def get_user_by_name(_), do: nil

  @doc """
  Finds or creates a user from Google OAuth data.

  The matching logic:
  1. Check for existing user by google_id → return if found
  2. Check for existing user where name matches Google email → link google_id
  3. Otherwise create new user with google_id and name

  ## Parameters
    - google_user: Map with Google profile data including "sub" (Google ID) and "email"

  ## Returns
    - {:ok, user} on success
    - {:error, changeset} on failure
  """
  def find_or_create_user(%{"sub" => google_id, "email" => email} = _google_user) do
    case get_user_by_google_id(google_id) do
      %User{} = user ->
        {:ok, user}

      nil ->
        # Try to find existing user by email (for migration from Clerk)
        case get_user_by_name(email) do
          %User{} = user ->
            # Link Google ID to existing user
            link_google_id(user, google_id)

          nil ->
            # Create new user
            create_user(%{google_id: google_id, name: email})
        end
    end
  end

  def find_or_create_user(_), do: {:error, :invalid_google_data}

  @doc """
  Creates a new user.
  """
  def create_user(attrs) do
    now = System.system_time(:millisecond)

    %User{}
    |> User.create_changeset(attrs)
    |> Ecto.Changeset.put_change(:created_at, now)
    |> Ecto.Changeset.put_change(:updated_at, now)
    |> Repo.insert()
  end

  @doc """
  Links a Google ID to an existing user.
  """
  def link_google_id(%User{} = user, google_id) do
    now = System.system_time(:millisecond)

    user
    |> User.link_google_changeset(%{google_id: google_id})
    |> Ecto.Changeset.put_change(:updated_at, now)
    |> Repo.update()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    now = System.system_time(:millisecond)

    user
    |> User.update_changeset(attrs)
    |> Ecto.Changeset.put_change(:updated_at, now)
    |> Repo.update()
  end

  @doc """
  Returns true if the user is an admin.
  """
  def admin?(%User{is_admin: true}), do: true
  def admin?(_), do: false
end
