# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- `mix phx.server` - Start development server
- `iex -S mix phx.server` - Start server with interactive Elixir shell
- `mix test` - Run tests
- `mix format` - Format code
- `mix ecto.migrate` - Run database migrations
- `mix ecto.rollback` - Rollback last migration
- `mix ecto.reset` - Drop, create, and migrate database

## Architecture

This is a fantasy sports tournament application built with Phoenix Framework, LiveView, Ecto with SQLite, and Google OAuth authentication.

### Key Components:
- **Database**: SQLite with Ecto ORM
- **Auth**: Google OAuth via elixir_auth_google
- **UI**: Phoenix LiveView with Tailwind CSS
- **Real-time**: LiveView for interactive team selection

### Data Model:
- **User**: Google OAuth users with admin flag
- **Tournament**: Contests with deadlines, team/price limits, and slugs for URLs
- **Team**: Belongs to tournaments, has name/price/points
- **Pick**: User selections for tournaments (stored as JSON team IDs)
- **IdealPick**: Optimal team selection for each tournament

### Contexts (Business Logic):
Contexts in `lib/fantasy/` handle business logic:
- `accounts.ex` - User management and authentication
- `tournaments.ex` - Tournament/team/pick operations
- `results.ex` - Tournament results, scoring, and ideal pick calculation
- `stats.ex` - Tournament metrics and statistics

### LiveViews:
LiveViews in `lib/fantasy_web/live/` handle UI:
- `home_live.ex` - Tournament listing
- `tournament_live/show.ex` - Team selection
- `tournament_live/results.ex` - Tournament results
- `tournament_live/popular.ex` - Popular picks analysis
- `tournament_live/stats.ex` - Tournament statistics
- `tournament_live/edit.ex` - Admin tournament editing
- `tournament_live/create.ex` - Admin tournament creation

### URL Structure:
- `/` - Home page with tournament listings
- `/tournaments/:slug` - Team selection (auth required)
- `/tournaments/:slug/results` - Tournament results (public)
- `/tournaments/:slug/popular` - Popular team picks (public)
- `/tournaments/:slug/stats` - Tournament statistics (public)
- `/tournaments/:slug/edit` - Admin tournament editing
- `/tournaments/create` - Admin tournament creation

### Key Patterns:
- LiveView for real-time UI updates
- Contexts for business logic separation
- Ecto schemas map to existing Prisma database (camelCase columns)
- Team selections stored as JSON strings in Pick.teamIds
- Tournament slugs used for URL routing
- Admin functionality gated by User.is_admin flag
- Auth plugs for route protection
