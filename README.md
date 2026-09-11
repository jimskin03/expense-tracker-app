# Ledger — Expense Tracker (expense-tracker-app)

A lightweight, single-file web app to track income, expenses, and recurring payments with visual analytics. Designed to be locally hosted (open index.html in a browser) and suitable as a minimal PWA/demo or starter template.

## Key characteristics
- **Single-file HTML app**: index.html contains markup, styles, and JavaScript.
- **Canonical ledger**: every record lives in one account-scoped table, `expense.transactions`, in the shared Supabase project. There is no REST backend — the browser talks to Supabase PostgREST directly through supabase-js.
- **Account-scoped ownership**: each row references an `expense.accounts` row whose `user_id` is the authenticated user. Record tables deliberately have no `user_id` column; Row Level Security plus composite foreign keys keep each user's ledger isolated.
- **Authentication/session**: the app uses the shared Cryptgreg Research Supabase session when the user is signed in on the main site. A password sign-in dialog is available from the top bar when no session is present.
- **Visual analytics**: doughnut chart showing expense breakdown by category with interactive date filtering.
- **Export**: CSV export of the ledger is provided.

## Features
- ✅ Add, edit, and delete income and expense records
- ✅ Reverse a posted entry without deleting or overwriting it
- ✅ Track recurring items (loans, utilities, subscriptions) and log payments
- ✅ Dashboard summary (total income, total expenses, net savings; transfers excluded)
- ✅ **Expense breakdown pie chart** with category-wise visualization
- ✅ **Interactive date range filters**: All Time, This Month, Last 7 Days, Last 30 Days, Custom Range
- ✅ **Filtered activity feed**: View ledger rows with reference numbers, source and status markers
- ✅ **Dynamic chart updates**: Chart automatically updates when date filter changes
- ✅ CSV export for offline analysis
- ✅ Compound growth calculator with monthly contribution and interest chart
- ✅ Keyboard shortcut: press `n` to open the Add page

## Quick links
- **Live UI**: open `index.html` in any modern browser
- **Main file**: `index.html`

## Table of contents
- [Quick start](#quick-start)
- [Usage](#usage)
- [What's New](#whats-new)
- [Developer notes](#developer-notes)
- [Data model](#data-model)
- [Contributing](#contributing)
- [License](#license)

---

## Quick start

1. Clone the repository:

```bash
git clone https://github.com/jimskin03/expense-tracker-app.git
cd expense-tracker-app
```

2. Open the app
   - **Option A (recommended for local testing)**: start a simple HTTP server and open the app in the browser:

   ```bash
   python -m http.server 8000
   # then visit http://localhost:8000 in your browser
   ```

   or

   ```bash
   npx serve .
   ```

   - **Option B**: open the file directly in the browser: double-click `index.html` or open it via `file://` URL. (Some browsers restrict certain APIs for file URLs; using a simple HTTP server avoids this.)

3. Apply the SQL migrations in `supabase/migrations/` to the shared Supabase project in filename order, by pasting each file into the project's Supabase SQL editor. `20260911090000_add_transactions_ledger.sql` creates `expense.transactions` and backfills the archived rows; `20260911090500_retire_legacy_expense_tables.sql` revokes write grants on the retired `expense.incomes` / `expense.expenses` tables. The archive migration preserves the old data in a non-exposed `archive` schema. After applying the ledger migration, run `supabase/validation/reconcile_transactions.sql` in the same editor and expect zero `FAIL` rows. The ledger migration requires PostgreSQL 15+.
4. Start using it: Sign in from the top bar, add income and expense records from the Add tab, view activity on the Records tab, and manage recurring payments on the Recurring tab.

## Usage

### Records Tab
- **Dashboard**: View total Income, Expenses, and Net Savings at the top. Transfers between your own accounts are shown in the feed but excluded from these tiles.
- **Expense Chart**: Visual doughnut chart showing spending breakdown by category. The chart only appears when you have expense data.
- **Date Filters**: Filter transactions using quick buttons (All Time, This Month, Last 7 Days, Last 30 Days) or set a custom date range. The filter applies to the whole ledger, so the feed, chart and totals describe the same window.
- **Activity Feed**: View filtered ledger rows sorted by date, each showing its reference number and marking non-`manual` sources and non-`posted` statuses. Manual, posted rows can be edited or deleted; every posted row can be reversed.

### Add Tab
- **Income Section**: Add income records with date, source (Salary, Bonus, Investment, etc.), and amount. Select "Others" to specify a custom source.
- **Expense Section**: Add expense records with date, category (Food, Transport, Utilities, etc.), optional description, and amount. Select "Others" to specify a custom category.
- **Clear Button**: Reset form fields without saving.

### Recurring Tab
- **Add Recurring Items**: Create recurring transactions like loans, utility bills, or subscriptions. Specify type (Loan, Utilities, Others), amount, and name.
- **Log Payment**: Click "Log payment" on any recurring item to instantly add it as an expense for today's date. The logged payment becomes an `expense.transactions` row with `source_type = 'recurring'` and `recurring_id` set.
- **Edit/Remove**: Modify or remove recurring items. The total of all recurring amounts is displayed at the top.
- **Total Display**: Shows sum of all tracked recurring amounts.

### Filtering & Analytics
- **All Time**: View all ledger rows ever recorded.
- **This Month**: Filter to current calendar month only.
- **Last 7 Days**: Show transactions from the past 7 days.
- **Last 30 Days**: Show transactions from the past 30 days.
- **Custom Range**: Select start and end dates to view a specific period. The activity feed and chart automatically update.

### CSV Export
- Click "Export CSV" on the Records page to download `ledger_export.csv` with the columns: `Reference, Type, Direction, Status, Source, Date, Category, Description, Amount`.

See `docs/USAGE.md` for a step-by-step guide with screenshots (if you add them) and common troubleshooting notes.

## What's New

### v2.0 - Analytics & Filtering
- **Doughnut Chart**: Visual breakdown of expenses by category with interactive legend showing amounts and percentages.
- **Date Range Filters**: Quick filters for common ranges plus custom date picker.
- **Smart Rendering**: Chart and activity feed update dynamically based on selected filter.
- **Responsive Design**: Chart adapts to mobile (single column) and desktop (two-column) layouts.
- **Chart.js Integration**: Uses Chart.js 4.4.0 from CDN for reliable visualization.

## Developer notes

This is a minimal single-file SPA. The entire app lives in `index.html`. Major responsibilities are organized roughly as follows:

- **Styling**: CSS variables at the top of the file (`:root`) control theme colors, radii, and layout. Chart-specific styles handle legend display and filter buttons.
- **State**: `categories` and `ledgerRows` (counted ledger rows read from the view), plus the derived arrays `incomes` (direction `in`, excluding transfers), `expenses` (direction `out`, excluding transfers), `transfers`, and `recurring`, and `activeFilter` for the current date range.
- **Persistence**: reads go through the `expense.counted_transactions` view (constant `COUNTED_VIEW`), writes go to `expense.transactions` (constant `TRANSACTION_TABLE`) by row `id` plus `account_id`. `CATEGORY_TABLE` is `categories` and `RECURRING_TABLE` is `recurring`. The select list is `LEDGER_COLUMNS`, which fetches `amount::text` and `signed_amount::text` so a balance never passes through a float. Every user has an `expense.accounts` row linked to `auth.users`; Row Level Security limits every operation to the owning account. There is no REST backend and no service-role credential in the browser — the client writes through PostgREST. Calculator inputs remain in memory and are not account records.
- **Rendering**:
  - `renderActivityFeed()`: displays the activity feed with optional date filtering
  - `renderDashboard()`: updates dashboard totals from integer cents
  - `renderRecurringList()`: displays recurring items
  - `renderChart()`: creates/updates doughnut chart and legend
- **Filtering**:
  - `getFilteredLedger()`: returns ledger rows matching the active date filter
  - `getFilteredExpenses()`: narrows the filtered ledger to `type = 'expense'`
  - `groupByCategory()`: aggregates expenses by category for charting
  - `setupFilterListeners()`: sets up date filter button handlers
- **Money**: `toCents`, `fromCents`, and `moneyFromCents` convert between PostgREST decimal strings and integer cents; all totals are integer arithmetic. Amount inputs are validated to at most two decimal places.
- **Actions**: `addIncome`, `addExpense`, `saveRecurring`, `editRecord`, `deleteRecord`, and `logRecurringPayment` perform row-level database operations by record ID; `reverseLedgerRow` calls the `reverse_transaction` database function.

### Adding New Features

If you plan to expand the project, add a dedicated table in the appropriate service schema and link it to that service's account boundary. For the expense tracker, records belong to `expense.accounts` through `account_id`; RLS must authorize the account's `user_id = auth.uid()`. Do not add unrelated service data to the expense tables or modify `auth.users` directly.

## Data model

The ledger migration creates `expense.transactions`, the canonical money ledger, and backfills the archived income and expense rows into it. Ownership is account-scoped: every row references `expense.accounts(id)`, and no record table carries a `user_id` column. Ownership flows `expense.transactions.account_id -> expense.accounts.user_id` and is enforced by RLS policies of the form `exists (select 1 from expense.accounts a where a.id = account_id and a.user_id = auth.uid())`, reinforced by composite foreign keys that pin related rows to the same account. The superseded `expense.incomes` and `expense.expenses` tables keep their data and stay readable, but their write grants are revoked so they cannot drift from the ledger.

```sql
-- expense.transactions
id uuid primary key,
account_id uuid not null references expense.accounts(id) on delete cascade,
reference_no text not null default expense.next_transaction_reference(),
type text not null check (type in ('expense', 'income', 'transfer', 'refund', 'adjustment')),
direction text not null check (direction in ('in', 'out')),
amount numeric(14, 2) not null check (amount > 0),
signed_amount numeric(14, 2)
  generated always as (case when direction = 'in' then amount else -amount end) stored,
record_date date not null,
category_id uuid null,
description text not null default '',
source_type text not null default 'manual'
  check (source_type in ('manual', 'receipt', 'recurring', 'import', 'api', 'ai', 'migration')),
source_ref text,
receipt_id uuid null,
recurring_id uuid null,
transfer_group_id uuid null,
reversal_of uuid null,
legacy_key text,
legacy_category text,
metadata jsonb not null default '{}'::jsonb,
status text not null default 'posted'
  check (status in ('pending', 'posted', 'voided', 'reversed')),
created_at timestamptz not null default now(),
updated_at timestamptz not null default now(),
unique (reference_no)
```

Key properties of the ledger:

- **Sign convention**: `amount` is always positive; `direction` carries the sign; `signed_amount` is a stored generated column equal to `amount` for `in` and `-amount` for `out`. Balances are `SUM(signed_amount)`. A CHECK pins direction to type: `expense -> out`, `income`/`refund -> in`, `transfer`/`adjustment` either.
- **Reporting rule**: counted rows are `status in ('posted', 'reversed')`, exposed as the view `expense.counted_transactions` (`security_invoker`). `pending` and `voided` are excluded. A reversed row and its compensating row must BOTH be counted or the pair would inflate the balance by the transaction amount, which is why reports read the view rather than `status = 'posted'`.
- **Reversal**: `expense.reverse_transaction(id, reason)` marks the original `status = 'reversed'` and posts a compensating row on the opposite side in the same account (a `refund` for an `out` row, an `adjustment` for an `in` row), linked by `reversal_of` and `metadata.reversal`. Nothing is overwritten. `voided` is the alternative: nothing compensates it, and it leaves reports.
- **Immutability**: a BEFORE UPDATE trigger freezes `amount`/`direction`/`type`/`record_date` on rows whose `source_type <> 'manual'` once posted (reverse and post a correction instead), always pins `id`/`account_id`/`reference_no`, and forbids rewriting `source_type`/`legacy_key`. The RLS DELETE policy allows hard deletion only for `source_type = 'manual'` rows that are not reversed.
- **Transfers**: two rows sharing a `transfer_group_id`, equal amount, opposite directions, two different accounts, enforced by a `DEFERRABLE INITIALLY DEFERRED` constraint trigger so a half-written transfer fails at COMMIT. Created atomically via `expense.create_transfer(from_account, to_account, amount, date, description)`, which is `SECURITY INVOKER` so RLS still decides what the caller may touch. Cross-currency transfers are rejected with an explicit error until FX support exists (accounts have a `currency` column; all accounts default to `MYR`). Transfers appear in the Activity feed but are excluded from the Income/Expenses/Net Savings tiles because moving money between your own accounts is not income or spending.
- **Reference numbers**: generated database-side by `expense.next_transaction_reference()` using the sequence `expense.transaction_reference_seq`, formatted `TXN-000000001`. The counter is global and monotonic — not dated and not gapless — and `COUNT()+1` is never used. `reference_no` is UNIQUE. The UUID stays the relational key; the reference exists for the UI, logs, support, agents, receipts and audit trails.
- **Idempotent migration**: the unique index `ux_transactions_migration_key` covers `(account_id, source_type, legacy_key)` where `legacy_key is not null`. `legacy_key` in the source tables is a per-user ordinal such as `'income:1'`, so it is NOT globally unique and the key MUST be account-scoped — a global `(source_type, legacy_key)` index would collide across users. Backfill uses `ON CONFLICT ... DO NOTHING`, so re-running the migration cannot duplicate rows.
- **Migration source**: the retired tables live in the non-exposed `archive` schema as `archive.expense_expense_records` and `archive.expense_income_records` (the names `archive.expenses` / `archive.incomes` are only fallbacks the migration probes for). The migration resolves candidates at runtime (`archive.*` first, then `public.*`). Rows whose owner has no `expense.accounts` row are skipped with a WARNING and are surfaced by the reconciliation check `source_rows_without_account`.

### Related tables

- **Categories** (`expense.categories`): account-scoped, with case-normalized uniqueness via the unique index `ux_categories_account_name_lower` on `(account_id, lower(name))`, so `Food` and `food` collapse to one category. `legacy_category` retains the original free-text string during migration.
- **Receipts** (`expense.receipts`): evidence only. Holds file/storage metadata, `extraction_model`, `confidence`, `extracted_total`, `extracted_date`, and `raw_extraction jsonb`. Access is read/write for the owning account only. A receipt never becomes a ledger row.
- **Recurring** (`expense.recurring`): rules that generate transactions, never ledger rows. It gained `category_id`, `frequency` (`daily`/`weekly`/`monthly`/`quarterly`/`yearly`, default `monthly`), `next_run_date`, `is_active`, `description`, and `metadata`. Logging a payment inserts an `expense.transactions` row with `source_type = 'recurring'` and `recurring_id` set.

`legacy_key` columns on the ledger retain the source position of backfilled records and prevent duplicate migration. `created_at` and `updated_at` are managed by PostgreSQL. The browser uses the exposed `expense` schema and never writes a caller-supplied owner ID to record rows.

CSV exports produce rows: `Reference, Type, Direction, Status, Source, Date, Category, Description, Amount`.

### Supabase authentication and data

The app connects to the shared Cryptgreg Research Supabase project for password authentication and shared sessions. `supabase/migrations/20260911090000_add_transactions_ledger.sql` creates `expense.transactions`, `expense.categories`, and `expense.receipts`, extends `expense.recurring`, and backfills the archived rows; `supabase/migrations/20260911090500_retire_legacy_expense_tables.sql` revokes write grants on the retired `expense.incomes` / `expense.expenses` tables while keeping them readable as rollback sources.

New records are written directly to `expense.transactions`, and edits/deletes target one database row by its UUID plus the current account ID. Calculator inputs remain local to the current page.

The migrations are applied by pasting them into the project's Supabase SQL editor (there is no CLI link on this host and no service-role credential is stored). After applying the ledger migration, run `supabase/validation/reconcile_transactions.sql` in the same editor and expect zero `FAIL` rows. Status: the ledger migrations are written and verified against a local PostgreSQL 17 reproduction of the migration chain, but are NOT yet applied to the production Supabase project.
## Runtime / Compatibility notes

- The app is a static HTML file and works in modern Chromium/Firefox/Safari browsers.
- Supabase authentication requires an internet connection and a redirect URL allowed by the Supabase project.
- Expense data is stored in Supabase and is available after signing in from another browser or device. Use CSV export for a portable backup.
- Chart.js is loaded from CDN. An internet connection is required for charts to render. You can download Chart.js locally if needed.
- If you deploy to GitHub Pages, the app will be served statically. Enable Pages in the repository settings and set the deployment branch to `main` and the folder to `/`.

## Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Mobile browsers with ES6 support

---

## Contributing
See `docs/CONTRIBUTING.md` for contribution guidelines. The project is intentionally small and opinions are light: keep changes minimal, prefer readability over micro-optimizations, and maintain backward compatibility with existing data structures.

## License
This repository is licensed under the MIT License (see `LICENSE`).

---

**Questions or feedback?** Open an issue on GitHub or check the docs folder for more detailed guides.
