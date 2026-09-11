# Ledger — Expense Tracker (expense-tracker-app)

A lightweight, single-file web app to track income, expenses, and recurring payments with visual analytics. Designed to be locally hosted (open index.html in a browser) and suitable as a minimal PWA/demo or starter template.

## Key characteristics
- **Single-file HTML app**: index.html contains markup, styles, and JavaScript.
- **Persistent data**: income, expense, and recurring records are stored in the shared Supabase project and scoped by the authenticated user ID. This makes records available across browsers and devices while keeping users isolated with Row Level Security.
- **Authentication/session**: the app uses the shared Cryptgreg Research Supabase session when the user is signed in on the main site. A password sign-in dialog is available from the top bar when no session is present.
- **Visual analytics**: doughnut chart showing expense breakdown by category with interactive date filtering.
- **Export**: CSV export of records is provided.

## Features
- ✅ Add, edit, and delete income and expense records
- ✅ Track recurring items (loans, utilities, subscriptions) and log payments
- ✅ Dashboard summary (total income, total expenses, net savings)
- ✅ **Expense breakdown pie chart** with category-wise visualization
- ✅ **Interactive date range filters**: All Time, This Month, Last 7 Days, Last 30 Days, Custom Range
- ✅ **Filtered activity feed**: View transactions based on selected date range
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

3. Apply the SQL migrations in `supabase/migrations/` to the shared Supabase project in filename order. The account-layer migration is `20260911080221_add_expense_accounts_layer.sql`; the archive migration is `20260911082916_archive_legacy_public_expense_tables.sql`. The archive migration preserves the old data in a non-exposed `archive` schema.
4. Start using it: Sign in from the top bar, add income and expense records from the Add tab, view activity on the Records tab, and manage recurring payments on the Recurring tab.

## Usage

### Records Tab
- **Dashboard**: View total Income, Expenses, and Net Savings at the top.
- **Expense Chart**: Visual doughnut chart showing spending breakdown by category. The chart only appears when you have expense data.
- **Date Filters**: Filter transactions using quick buttons (All Time, This Month, Last 7 Days, Last 30 Days) or set a custom date range.
- **Activity Feed**: View filtered transactions sorted by date. Edit or delete individual records here.

### Add Tab
- **Income Section**: Add income records with date, source (Salary, Bonus, Investment, etc.), and amount. Select "Others" to specify a custom source.
- **Expense Section**: Add expense records with date, category (Food, Transport, Utilities, etc.), optional description, and amount. Select "Others" to specify a custom category.
- **Clear Button**: Reset form fields without saving.

### Recurring Tab
- **Add Recurring Items**: Create recurring transactions like loans, utility bills, or subscriptions. Specify type (Loan, Utilities, Others), amount, and name.
- **Log Payment**: Click "Log payment" on any recurring item to instantly add it as an expense for today's date.
- **Edit/Remove**: Modify or remove recurring items. The total of all recurring amounts is displayed at the top.
- **Total Display**: Shows sum of all tracked recurring amounts.

### Filtering & Analytics
- **All Time**: View all transactions ever recorded.
- **This Month**: Filter to current calendar month only.
- **Last 7 Days**: Show transactions from the past 7 days.
- **Last 30 Days**: Show transactions from the past 30 days.
- **Custom Range**: Select start and end dates to view a specific period. The activity feed and chart automatically update.

### CSV Export
- Click "Export CSV" on the Records page to download a spreadsheet of all income and expense records.

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
- **State**: five in-memory arrays `incomes`, `expenses`, `recurring`, plus `activeFilter` for current date range.
- **Persistence**: authenticated records are stored as individual rows in the exposed `expense` schema: `expense.incomes`, `expense.expenses`, and `expense.recurring`. Every user has an `expense.accounts` row linked to `auth.users`; record rows reference that account through `account_id`, and Row Level Security limits every operation to the owning user. Calculator inputs remain in memory and are not account records.
- **Rendering**: 
  - `renderActivityFeed()`: displays activity feed with optional date filtering
  - `renderDashboard()`: updates dashboard totals
  - `renderRecurringList()`: displays recurring items
  - `renderChart()`: creates/updates doughnut chart and legend
- **Filtering**: 
  - `getFilteredExpenses()`: returns expenses matching the active date filter
  - `groupByCategory()`: aggregates expenses by category for charting
  - `setupFilterListeners()`: sets up date filter button handlers
- **Actions**: `addIncome`, `addExpense`, `saveRecurring`, `editRecord`, `deleteRecord`, and `logRecurringPayment` perform row-level database operations by record ID.

### Adding New Features

If you plan to expand the project, add a dedicated table in the appropriate service schema and link it to that service's account boundary. For the expense tracker, records belong to `expense.accounts` through `account_id`; RLS must authorize the account's `user_id = auth.uid()`. Do not add unrelated service data to the expense tables or modify `auth.users` directly.

## Data model

The account-layer migration creates an account row for each existing Supabase Auth user and copies normalized rows beneath that account. The new tables are `expense.incomes`, `expense.expenses`, and `expense.recurring`; each has an `account_id` foreign key to `expense.accounts(id)` with cascading deletion. The superseded public tables are now archived in the non-exposed `archive` schema and are retained only for rollback until explicitly deleted.

```sql
-- expense.accounts
id uuid primary key,
user_id uuid not null unique references auth.users(id) on delete cascade,
currency text not null default 'MYR'

-- expense.incomes
id uuid primary key,
account_id uuid not null references expense.accounts(id) on delete cascade,
type text not null default 'income',
record_date date not null,
source text not null,
amount numeric(12, 2) not null check (amount > 0)

-- expense.expenses
id uuid primary key,
account_id uuid not null references expense.accounts(id) on delete cascade,
type text not null default 'expense',
record_date date not null,
category text not null,
description text not null default '',
amount numeric(12, 2) not null check (amount > 0)

-- expense.recurring
id uuid primary key,
account_id uuid not null references expense.accounts(id) on delete cascade,
type text not null check (type in ('Loan', 'Utilities', 'Others')),
name text not null,
amount numeric(12, 2) not null check (amount > 0)
```

`legacy_key` columns on the new tables retain the source position of backfilled records and prevent duplicate migration. `created_at` and `updated_at` are managed by PostgreSQL. The browser uses the exposed `expense` schema and never writes a caller-supplied owner ID to record rows.

CSV exports produce rows: `Type, Date, Category/Source, Description, Amount`.

### Supabase authentication and data

The app connects to the shared Cryptgreg Research Supabase project for password authentication and shared sessions. The migration `supabase/migrations/20260911080221_add_expense_accounts_layer.sql` creates the account hierarchy, and `supabase/migrations/20260911082916_archive_legacy_public_expense_tables.sql` moves the old public expense tables into a non-exposed archive schema without deleting their data.

New records are written directly to their dedicated account-scoped relational table, and edits/deletes target one database row by its UUID plus the current account ID. Calculator inputs remain local to the current page.
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
