# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DraftGuru is a Phoenix web application for NBA Draft analytics and player data management. It tracks player combine statistics, biographical information, and provides analytics capabilities including player similarity analysis and performance metrics.

## Development Commands

### Initial Setup
```bash
mix setup                    # Install deps, setup DB, build assets
```

### Running the Application
```bash
mix phx.server              # Start Phoenix server (localhost:4000)
iex -S mix phx.server       # Start with interactive console
```

### Database Operations
```bash
mix ecto.create             # Create database
mix ecto.migrate            # Run migrations
mix ecto.reset              # Drop, create, migrate, and seed
mix run priv/repo/seeds.exs # Run seeds manually
```

### Testing
```bash
mix test                    # Run all tests
mix test test/path/to/specific_test.exs  # Run specific test
```

### Asset Management
```bash
mix assets.setup           # Install Tailwind and esbuild
mix assets.build           # Build CSS and JS assets
mix assets.deploy          # Build and minify for production
```

### Docker Development (Preferred)
```bash
make dev-up                # Start development environment
make dev-build             # Build development containers
make dev-up-build          # Build and start containers
make dev-migrate           # Run migrations in container
make dev-seed              # Run seeds in container
make dev-stop              # Stop containers
make dev-down              # Stop and remove containers
```

## Architecture Overview

### Core Domain Contexts

**Players Context (`lib/draft_guru/players.ex`)**
- Manages canonical player records (first_name, last_name, middle_name, suffix)
- Central entity that other contexts reference
- Handles player lookup and search functionality

**Player Infos Context (`lib/draft_guru/player_infos.ex`)**
- Extended player biographical data (birth dates, schools, hometown)
- Image management for player photos (headshots, stylized images)
- NBA status tracking and bulk operations

**Player Combine Stats Context (`lib/draft_guru/player_combine_stats.ex`)**
- NBA Draft Combine performance data (height, weight, agility, vertical leap)
- Complex data ingestion pipeline with atomic upsert operations
- Measurement conversions and data validation

**Accounts Context (`lib/draft_guru/accounts.ex`)**
- User authentication and authorization
- Role-based access control (admin, contributor, user)
- Complete auth flow with email confirmation and password reset

### Analytics System

**Metrics (`lib/draft_guru/metrics/`)**
- `player_combine_stat_metrics.ex`: Statistical calculations (z-scores, percentiles)
- `player_combine_stat_neighbors.ex`: Player similarity analysis via nearest neighbors
- Supports multiple comparison contexts (draft class vs NBA players)

### Data Pipeline

**Draft Combine Stats Pipeline (`lib/draft_guru/draft_combine_stats_pipeline.ex`)**
- ETL operations for importing combine data from CSV files
- Player record matching and reconciliation
- Data validation and error handling

**Data Collection Utilities (`lib/draft_guru/data_collection/`)**
- String processing and name standardization
- Measurement parsing (height formats, weight conversions)
- CSV export functionality

### Database Schema Key Points

- `player_canonical`: Core player identity table
- `player_infos`: Extended biographical data with image fields
- `player_combine_stats`: Combine performance metrics
- `player_id_lookups`: External data source ID mapping
- `users` and `user_roles`: Authentication system
- Analytics tables for metrics and similarity calculations

### Web Layer Structure

**Authentication & Authorization**
- Basic auth middleware for registration/login routes
- Admin-only access for data management interfaces
- User session management with token-based auth

**Admin Data Management Routes** (`/models/*`)
- Player canonical records: `/models/player_canonical`
- Player information: `/models/player_info` (includes bulk update)
- Combine statistics: `/models/player_combine_stats`
- ID lookups: `/models/player_id_lookup` (read-only)

### Key Development Notes

- Uses PostgreSQL with citext extension for case-insensitive emails
- Image uploads handled via Waffle uploader
- Extensive use of Ecto changesets for data validation
- Seeds require ADMIN_EMAIL and ADMIN_PASSWORD environment variables
- CSV data files placed in `priv/data_files/` for seeding
- LiveDashboard available at `/dev/dashboard` in development

### Testing Strategy

- Uses ExUnit with Ecto sandbox mode
- Fixtures defined in `test/support/fixtures/`
- Test coverage for core contexts (accounts, players)
- Controller tests for authentication and CRUD operations