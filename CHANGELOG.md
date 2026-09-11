# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-09-11
- Normalize income, expense, and recurring records into dedicated Supabase tables.
- Backfill existing JSON records without dropping the legacy table.
- Use database-generated record IDs and row-level insert/update/delete operations.
- Add database constraints, indexes, timestamp triggers, and per-user RLS policies.

## [0.1.0] - 2026-07-05
- Initial public release
- Single-file web app: `index.html` (UI, JS, CSS)
- Features: add/edit/delete income & expense, recurring items, CSV export
