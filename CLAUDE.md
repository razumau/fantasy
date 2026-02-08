# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- `mix setup` - Full setup: deps, database, assets
- `mix phx.server` - Start dev server (port 4001, not 4000)
- `iex -S mix phx.server` - Start server with interactive shell
- `mix test` - Run all tests (auto-creates and migrates test DB)
- `mix test path/to/file_test.exs` - Run single test file
- `mix test path/to/file_test.exs:42` - Run single test at line
- `mix format` - Format code
- `mix ecto.migrate` - Run database migrations
- `mix ecto.reset` - Drop, create, migrate, and seed database
- `mix precommit` - Compile (warnings-as-errors), format, and test

## Architecture

Fantasy sports tournament app built with Phoenix 1.8, LiveView, Ecto with SQLite, and Google OAuth.

### Database: Prisma Legacy Schema

This app was migrated from Next.js/Prisma. The database retains Prisma conventions:
- **Table names**: PascalCase (`User`, `Tournament`, `Team`, `Pick`, `IdealPick`)
- **Column names**: camelCase (`maxTeams`, `teamIds`, `isAdmin`, `tournamentId`)
- **Ecto mapping**: All schemas use `:source` option to map snake_case Elixir fields to camelCase DB columns:
  ```elixir
  field :max_teams, :integer, source: :maxTeams
  ```
- **Timestamps**: Stored as Unix milliseconds (bigint), not Ecto's naive_datetime. Custom type `Fantasy.Ecto.UnixTimestamp` handles conversion.
- **JSON fields**: `Pick.team_ids` and `IdealPick.team_ids` store JSON arrays as strings. Use `Pick.get_team_ids/1` and `Pick.encode_team_ids/1` helpers.
- **Legacy field**: `clerkId` on User is from old Clerk auth, now nullable.

### SQLite Migration Caveats

SQLite doesn't support `ALTER COLUMN`. Schema changes require the recreate pattern:
1. `@disable_ddl_transaction true`
2. `PRAGMA foreign_keys = OFF`
3. Create new table, copy data, drop old, rename
4. `PRAGMA foreign_keys = ON`

### Auth Flow

- Google OAuth via `elixir_auth_google` (requires `dev.secret.exs` with client credentials locally)
- `FetchCurrentUser` plug runs on all browser requests, assigns `:current_user`
- `RequireAuth` plug redirects to `/auth/login?return_to=...`
- `RequireAdmin` plug checks `User.is_admin`

### LiveView Patterns

- **Auth**: Uses `on_mount` hooks (`require_auth`, `maybe_auth`, `require_admin`) in `FantasyWeb.Live.Hooks`
- **Async saves**: `send(self(), {:save_picks, ...})` pattern for non-blocking DB writes. In tests, call `render(view)` after actions to process async messages before assertions.
- **Optimistic locking**: `Pick.version` field prevents concurrent update conflicts.

### Contexts (Business Logic)

Contexts in `lib/fantasy/`:
- `accounts.ex` - User management and authentication
- `tournaments.ex` - Tournament/team/pick operations
- `results.ex` - Tournament results, scoring, and ideal pick calculation
- `stats.ex` - Tournament metrics and statistics

### LiveViews

LiveViews in `lib/fantasy_web/live/`:
- `home_live.ex` - Tournament listing
- `tournament_live/show.ex` - Team selection (auth required)
- `tournament_live/results.ex` - Tournament results (public)
- `tournament_live/popular.ex` - Popular picks analysis
- `tournament_live/stats.ex` - Tournament statistics (public)
- `tournament_live/edit.ex` - Admin tournament editing
- `tournament_live/create.ex` - Admin tournament creation

### Route Protection

- **Public**: `/`, `/tournaments/:slug/results`, `/tournaments/:slug/popular`, `/tournaments/:slug/stats`
- **Auth required**: `/tournaments/:slug` (team selection)
- **Admin required**: `/tournaments/create`, `/tournaments/:slug/edit`

### Testing

- Test fixtures in `test/support/fixtures.ex`: `create_user/1`, `create_tournament/1`, `create_team/2`, `setup_tournament_with_teams/1`, `log_in_user/2`
- Context tests use `Fantasy.DataCase`, LiveView tests use `FantasyWeb.ConnCase`

### Deployment

Fly.io (Warsaw) with SQLite + Litestream S3 replication. Entrypoint restores from S3 backup, runs migrations, then starts Litestream which execs the Phoenix server.
