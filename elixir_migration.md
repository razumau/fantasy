# Migration Plan: Next.js to Phoenix/Elixir with LiveView

## Progress

| Phase | Status | Commits |
|-------|--------|---------|
| 1. Project Setup | ✅ Complete | `964f270`, `00c72b9` |
| 2. Database Migration | ✅ Complete | `d8bf0d1` |
| 3. Authentication | ✅ Complete | - |
| 4. Contexts | ✅ Complete | - |
| 5. LiveViews | ✅ Complete | - |
| 6. Deployment | ✅ Complete | - |
| 7. Migration Execution | ⬜ Not started | - |

### Completed Work

**Phase 1: Project Setup** (3 commits)
- Removed Next.js files, preserved database backup
- Created Phoenix 1.8 project with SQLite, LiveView, Tailwind
- Added dependencies: elixir_auth_google, finch, xlsxir, timex

**Phase 2: Database Migration** (1 commit)
- Created all 5 Ecto schemas matching Prisma tables
- Custom `Fantasy.Ecto.UnixTimestamp` type for Prisma millisecond timestamps
- Base tables migration + google_id migration
- Tested schemas with production database backup

**Phase 3: Authentication**
- Added `elixir_auth_google` config in dev.exs and runtime.exs
- Created `Fantasy.Accounts` context with user management functions
- Created `AuthController` with login/callback/logout actions
- Created auth plugs: `FetchCurrentUser`, `RequireAuth`, `RequireAdmin`
- Created LiveView hooks: `:require_auth`, `:require_admin`, `:maybe_auth`
- Updated router with auth routes and pipelines

**Phase 4: Contexts**
- Created `Fantasy.Tournaments` context with tournament/team/pick CRUD
- Created `Fantasy.Results` context with rankings and knapsack algorithm
- Created `Fantasy.Stats` context with tournament metrics

**Phase 5: LiveViews**
- Created `HomeLive` for tournament listing (open/closed)
- Created `TournamentLive.Show` for team selection with real-time updates
- Created `TournamentLive.Results` for tournament rankings
- Created `TournamentLive.Popular` for popular picks analysis
- Created `TournamentLive.Stats` for tournament statistics
- Created `TournamentLive.Edit` for admin tournament editing
- Created `TournamentLive.Create` for admin tournament creation
- Updated router with all routes and pipelines
- Updated app layout with auth-aware header

**Phase 6: Deployment**
- Created multi-stage Dockerfile (Elixir 1.18.3/OTP 27, Debian bookworm)
- Added litestream for S3 backup/restore of SQLite database
- Created entrypoint script: restore -> migrate -> replicate
- Created `Fantasy.Release` module for production migrations
- Updated fly.toml for Phoenix (port 4001, /data mount)
- Updated litestream.yml to exec Phoenix release

---

## Overview
Migrate the fantasy sports tournament app from Next.js/React to Phoenix/Elixir with LiveView. Replace Clerk authentication with elixir_auth_google. Keep SQLite with fly.io + litestream.

## Key Decisions
- **User migration**: Match existing users by email when they log in with Google
- **Data structure**: Keep JSON teamIds as strings (no normalization)
- **Deployment**: In-place replacement of the existing fly.io app

---

## Phase 1: Project Setup

### 1.1 Create Phoenix Project
```bash
mix phx.new fantasy --database sqlite3 --no-mailer --no-dashboard
```

### 1.2 Dependencies (mix.exs)
```elixir
{:phoenix, "~> 1.7.14"},
{:phoenix_live_view, "~> 1.0.0"},
{:ecto_sqlite3, "~> 0.17"},
{:elixir_auth_google, "~> 1.6"},
{:xlsxir, "~> 1.6"},        # XLSX parsing
{:finch, "~> 0.18"},        # HTTP client
{:timex, "~> 3.7"},         # Date utilities
{:tailwind, "~> 0.2"}
```

### 1.3 Project Structure
```
lib/fantasy/
  accounts/           # User context (userService equivalent)
  tournaments/        # Tournament context (tournamentService equivalent)
  results/            # Results context (resultsService equivalent)
  stats/              # Stats context (statsService equivalent)
lib/fantasy_web/
  live/
    home_live.ex
    tournament_live/
      show.ex         # Team selection
      results.ex
      popular.ex
      stats.ex
      edit.ex
      create.ex
  plugs/
    require_auth.ex
    require_admin.ex
```

---

## Phase 2: Database Migration

### 2.1 Copy Existing Database
Download production SQLite database to use with Ecto.

### 2.2 Ecto Schemas (matching Prisma column names)

**User** (`lib/fantasy/accounts/user.ex`)
- Map `clerkId` → `clerk_id` (source option)
- Add `google_id` field (nullable initially)
- Map `isAdmin` → `is_admin`

**Tournament** (`lib/fantasy/tournaments/tournament.ex`)
- Map camelCase fields: `maxTeams`, `maxPrice`, `spreadsheetUrl`, etc.
- Implement `open?/1` function for deadline check

**Team** (`lib/fantasy/tournaments/team.ex`)
- Map `tournamentId` → `tournament_id`

**Pick** (`lib/fantasy/tournaments/pick.ex`)
- Keep `teamIds` as string, parse with `Jason.decode!/1`
- Add `get_team_ids/1` helper function

**IdealPick** (`lib/fantasy/tournaments/ideal_pick.ex`)
- Same JSON string handling as Pick

### 2.3 Migration to Add google_id
```elixir
alter table(:User) do
  add :google_id, :string
end
create unique_index(:User, [:google_id])
```

---

## Phase 3: Authentication

### 3.1 Google OAuth Setup
- Create Google Cloud project
- Configure OAuth consent screen
- Generate client ID/secret
- Set redirect URI: `https://fantasy.razumau.net/auth/google/callback`

### 3.2 Auth Controller (`lib/fantasy_web/controllers/auth_controller.ex`)
- `login/2`: Redirect to Google OAuth
- `callback/2`: Handle OAuth callback, find/create user
- `logout/2`: Clear session

### 3.3 User Matching Logic
When Google OAuth callback received:
1. Check for existing user by `google_id` → return if found
2. Check for existing user where `name` matches Google email → link `google_id`
3. Otherwise create new user with `google_id` and `name`

### 3.4 Auth Plugs
- `RequireAuth`: Check session for user_id, redirect to login if missing
- `RequireAdmin`: Check user.is_admin flag, redirect if false

### 3.5 LiveView Hooks (`lib/fantasy_web/live/hooks.ex`)
- `on_mount(:require_auth, ...)`: For protected LiveViews
- `on_mount(:require_admin, ...)`: For admin LiveViews
- `on_mount(:maybe_auth, ...)`: For public pages with optional user

---

## Phase 4: Contexts (Business Logic)

### 4.1 Accounts Context
- `get_user/1`, `get_user!/1`
- `get_user_by_google_id/1`
- `find_or_create_user/1` - implements email matching logic
- `admin?/1`

### 4.2 Tournaments Context
- `get_tournament_by_slug/1`, `get_tournament_by_slug!/1`
- `list_open_tournaments/0`, `list_closed_tournaments/0`
- `list_teams_for_tournament/1`
- `get_user_picks/2`, `save_picks/4`
- `get_popular_teams/1`
- `create_tournament/2`, `update_tournament/3`

### 4.3 Results Context
- `get_tournament_results/1` - calculate rankings
- `get_ideal_pick/1` - fetch optimal selection
- `update_ideal_pick/1` - run knapsack algorithm
- `calculate_ideal_pick/3` - port knapsack from TypeScript

### 4.4 Stats Context
- `get_team_stats/1`
- `get_tournament_metrics/1`

---

## Phase 5: LiveViews

### 5.1 Router Configuration
```elixir
# Public routes
live "/", HomeLive
live "/privacy", PrivacyLive
live "/tournaments/:slug/results", TournamentLive.Results
live "/tournaments/:slug/popular", TournamentLive.Popular
live "/tournaments/:slug/stats", TournamentLive.Stats

# Auth routes (regular controllers)
get "/auth/login", AuthController, :login
get "/auth/google/callback", AuthController, :callback
delete "/auth/logout", AuthController, :logout

# Protected routes
live "/tournaments/:slug", TournamentLive.Show

# Admin routes
live "/tournaments/create", TournamentLive.Create
live "/tournaments/:slug/edit", TournamentLive.Edit
```

### 5.2 HomeLive
- Mount: Fetch open and closed tournaments
- Render: List with links to tournament pages

### 5.3 TournamentLive.Show (Team Selection)
- Mount: Load tournament, teams, user's picks
- State: `selected_teams`, `selected_team_ids` (MapSet), `total_selected_price`, `version`
- Event `toggle_team`: Validate max teams/price, update selection, save async
- Render: Grid layout with teams table, selected teams sidebar, tournament info

### 5.4 TournamentLive.Results
- Mount: Fetch results and ideal pick
- Render: Rankings table with player names, teams, points

### 5.5 TournamentLive.Popular
- Mount: Fetch popular teams data
- Render: Teams sorted by selection frequency

### 5.6 TournamentLive.Stats
- Mount: Fetch team stats and tournament metrics
- Render: Stats table with difficulty bias, accuracy metrics

### 5.7 TournamentLive.Edit (Admin)
- Mount: Fetch tournament and teams
- Events: `validate`, `save`, `update_team`
- Render: Form for tournament details, inline editable teams table

### 5.8 TournamentLive.Create (Admin)
- Mount: Empty form
- Events: `validate`, `submit`
- Render: Form with team textarea input

---

## Phase 6: Deployment

### 6.1 Dockerfile
- Multi-stage build with Elixir 1.16
- Install litestream in final stage
- Mount volume at /data for SQLite

### 6.2 litestream.yml
```yaml
dbs:
  - path: /data/sqlite.db
    replicas:
      - type: s3
        endpoint: ${AWS_ENDPOINT_URL_S3}
        bucket: ${BUCKET_NAME}
```

### 6.3 Entrypoint Script
1. Restore database from litestream backup
2. Run Ecto migrations
3. Start litestream replication (which execs Phoenix server)

### 6.4 fly.toml Updates
- Update build section for Phoenix
- Add PHX_HOST environment variable
- Keep existing mount configuration

### 6.5 Environment Variables
```
SECRET_KEY_BASE=...
PHX_HOST=fantasy.razumau.net
DATABASE_URL=ecto://localhost/data/sqlite.db
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REDIRECT_URI=https://fantasy.razumau.net/auth/google/callback
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_ENDPOINT_URL_S3=...
BUCKET_NAME=...
```

---

## Phase 7: Migration Execution

### 7.1 Pre-Migration
1. Set up Google OAuth credentials
2. Test Phoenix app locally with copy of production database
3. Take final database backup

### 7.2 Cutover Steps
```bash
# 1. Take final backup
fly ssh console -C "sqlite3 /data/sqlite.db .dump" > final_backup.sql

# 2. Scale down Next.js
fly scale count 0

# 3. Deploy Phoenix (in-place)
fly deploy

# 4. Verify
curl https://fantasy.razumau.net/
```

### 7.3 Rollback Plan
```bash
# Restore Next.js from git and redeploy
git checkout main
fly deploy

# Restore database if needed
fly ssh console -C "sqlite3 /data/sqlite.db" < final_backup.sql
```

---

## Critical Files Reference

| Current File | Purpose | Phoenix Equivalent |
|--------------|---------|-------------------|
| `prisma/schema.prisma` | Database schema | `lib/fantasy/*/` schemas |
| `src/services/tournamentService.ts` | Tournament logic | `lib/fantasy/tournaments.ex` |
| `src/services/resultsService.ts` | Results + knapsack | `lib/fantasy/results.ex` |
| `src/services/userService.ts` | User management | `lib/fantasy/accounts.ex` |
| `app/actions.ts` | Server mutations | LiveView event handlers |
| `middleware.ts` | Route protection | Router pipelines + plugs |
| `app/tournaments/[slug]/TeamsSelector.tsx` | Team selection UI | `TournamentLive.Show` |

---

## Implementation Order

1. **Phoenix project setup** with dependencies
2. **Ecto schemas** matching existing database
3. **Accounts context** with Google OAuth
4. **Tournaments context** (basic CRUD)
5. **HomeLive** and **TournamentLive.Show**
6. **Results context** with knapsack algorithm port
7. **TournamentLive.Results**, **Popular**, **Stats**
8. **Admin LiveViews** (Create, Edit)
9. **Spreadsheet import** functionality
10. **Deployment configuration**
11. **Testing with production data copy**
12. **Production migration**
