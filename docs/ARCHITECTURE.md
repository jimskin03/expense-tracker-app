# Architecture notes — Ledger (expense-tracker-app)

Ledger is a minimal single-file SPA implemented in `index.html`. Authentication is shared with Cryptgreg Research through Supabase Auth and a root-domain session cookie. Record data is stored in normalized Supabase tables with row-level security.

## 1. Application structure

- CSS variables and theme — top of `index.html`.
- HTML markup — Records, Add, Recurring, and Calculator pages toggled with `.page` and `.active`.
- JavaScript — one inline script near the bottom of `index.html`.
- Supabase migrations — `supabase/migrations/20260911074622_normalize_expense_tracker_records.sql`, `supabase/migrations/20260911080221_add_expense_accounts_layer.sql`, and `supabase/migrations/20260911082916_archive_legacy_public_expense_tables.sql`.

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

The account-scoped schema stores one database row per record beneath the authenticated user's account:

- `expense.accounts` — `id`, `user_id`, `currency`, timestamps; one account per Auth user today.
- `expense.incomes` — `id`, `account_id`, `type`, `record_date`, `source`, `amount`.
- `expense.expenses` — `id`, `account_id`, `type`, `record_date`, `category`, `description`, `amount`.
- `expense.recurring` — `id`, `account_id`, `type`, `name`, `amount`.

Each table has:

- A database-generated UUID primary key.
- A foreign key through `expense.accounts` to `auth.users(id)` with `on delete cascade`.
- Positive amount and required-field constraints.
- An account-leading index for ownership-filtered queries.
- Database-managed `created_at` and `updated_at` timestamps.
- RLS policies for authenticated SELECT/INSERT/UPDATE/DELETE operations.

The browser creates or resolves the current user's account, then writes only `account_id` on records. RLS independently verifies that the account belongs to `auth.uid()`; client-side account filters provide defense in depth.

## 4. Migration and rollback

The account-layer migration copies the normalized rows under `expense.accounts` and the archive migration moves the source tables into the non-exposed `archive` schema. Archived data is retained for rollback; it is not part of the application API and the public schema itself remains available for Supabase compatibility.

Before permanently deleting the archived tables:

1. Confirm the live application has no references to the archive schema.
2. Keep an export or backup if the rollback window is still required.
3. Obtain explicit approval for a separate destructive cleanup migration.

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
