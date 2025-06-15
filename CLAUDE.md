# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- `pnpm dev` - Start development server (generates Prisma client first)
- `pnpm build` - Build for production (generates Prisma client, pushes DB schema, seeds DB)
- `pnpm start` - Start production server
- `pnpm lint` - Run ESLint
- `pnpm test` - Run Jest tests
- `prisma db push` - Push schema changes to database
- `prisma db seed` - Seed database with initial data
- `prisma generate` - Generate Prisma client

## Architecture

This is a fantasy sports tournament application built with Next.js 14 (App Router), Prisma ORM with SQLite, Clerk authentication, and Chakra UI.

### Key Components:
- **Database**: SQLite with Prisma ORM
- **Auth**: Clerk for user authentication 
- **UI**: Chakra UI with custom theme
- **Styling**: Tailwind CSS + Chakra UI

### Data Model:
- **User**: Clerk-based users with admin flag
- **Tournament**: Contests with deadlines, team/price limits, and slugs for URLs
- **Team**: Belongs to tournaments, has name/price/points
- **Pick**: User selections for tournaments (stored as JSON team IDs)
- **IdealPick**: Optimal team selection for each tournament

### Service Layer:
Services in `src/services/` handle business logic:
- `tournamentService.ts` - Tournament/team/pick operations
- `userService.ts` - User management
- `resultsService.ts` - Tournament results and scoring

### URL Structure:
- `/tournaments/[tournamentSlug]` - Main tournament page with team selection
- `/tournaments/[tournamentSlug]/popular` - Popular team picks analysis
- `/tournaments/[tournamentSlug]/results` - Tournament results and ideal picks
- `/tournaments/[tournamentSlug]/edit` - Admin tournament editing

### Key Patterns:
- Server Components for data fetching
- Services use Prisma for database operations
- Team selections stored as JSON arrays in Pick.teamIds
- Tournament slugs used for URL routing
- Admin functionality gated by User.isAdmin flag