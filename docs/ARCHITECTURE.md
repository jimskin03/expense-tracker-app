# Architecture notes — Ledger (expense-tracker-app)

Ledger is a minimal single-file SPA implemented in `index.html`. Authentication is shared with Cryptgreg Research through Supabase Auth and a root-domain session cookie. Record data is stored in normalized Supabase tables with row-level security.

## 1. Application structure

- CSS variables and theme — top of `index.html`.
- HTML markup — Records, Add, Recurring, and Calculator pages toggled with `.page` and `.active`.
- JavaScript — one inline script near the bottom of `index.html`.
- Supabase migration — `supabase/migrations/20260911074622_normalize_expense_tracker_records.sql`.

## 2. JavaScript responsibilities

- Auth/session: `renderAuth`, `ensureSignedIn`, and Supabase Auth listeners.
- Data loading: `loadAll` reads the three record tables for the authenticated session.
- Row persistence: `insertRecord`, `updateRecordRow`, and `deleteRecordRow` perform ID-based CRUD.
- Forms: `addIncome`, `addExpense`, `clearIncomeForm`, and `clearExpenseForm`.
- Editing/deletion: `editRecord` enters edit mode without deleting the original; the form submits an update by UUID.
- Recurring records: `saveRecurring`, `editRecurring`, `deleteRecurring`, and `logRecurringPayment`.
- Rendering: `renderActivityFeed`, `renderDashboard`, `renderRecurringList`, and `renderChart`.
- Utilities: filtering, CSV export, escaping, calculator, and category helpers.

## 3. Relational storage contract

The normalized schema stores one database row per record:

- `public.expense_income_records` — `id`, `user_id`, `type`, `record_date`, `source`, `amount`.
- `public.expense_expense_records` — `id`, `user_id`, `type`, `record_date`, `category`, `description`, `amount`.
- `public.expense_recurring_records` — `id`, `user_id`, `type`, `name`, `amount`.

Each table has:

- A database-generated UUID primary key.
- A foreign key to `auth.users(id)` with `on delete cascade`.
- Positive amount and required-field constraints.
- A composite index beginning with `user_id`.
- Database-managed `created_at` and `updated_at` timestamps.
- RLS policies for authenticated SELECT/INSERT/UPDATE/DELETE operations.

The browser includes `user_id` on inserts because Supabase requires a row value, but authorization is enforced independently by the RLS `auth.uid() = user_id` policy. Reads, updates, and deletes are also filtered by the current user in the client for defense in depth.

## 4. Migration and rollback

The normalization migration backfills the legacy JSON arrays using ordinal `legacy_key` values so duplicate records remain distinct. It is idempotent for backfill rows and does not drop `public.expense_tracker_data`. The old table remains available as a rollback source until the normalized deployment has completed its verification window.

Before retiring the legacy table:

1. Compare per-user counts and monetary totals between old and new storage.
2. Verify live add, reload, update, delete, recurring payment, filtering, and CSV flows.
3. Confirm account isolation with two authenticated accounts.
4. Obtain explicit approval for a separate destructive cleanup migration.

## 5. Adding a future service

Create a dedicated table rather than extending expense tables:

```sql
create table public.service_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index service_records_user_id_idx
  on public.service_records(user_id);
```

Enable RLS and add separate SELECT/INSERT/UPDATE/DELETE policies using `auth.uid() = user_id`. Do not modify `auth.users` directly or rely on the browser alone for authorization.

## 6. Security and privacy

- Supabase Auth owns account identity.
- The publishable key is safe for browser use; service-role credentials must never be shipped to the client.
- RLS is the authoritative data-isolation boundary.
- User emails, access tokens, and financial records must not be written to debug logs or exposed in documentation.
