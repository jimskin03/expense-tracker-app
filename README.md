# Ledger — Expense Tracker (expense-tracker-app)

A lightweight, single-file web app to track income, expenses, and recurring payments. Designed to be locally hosted (open index.html in a browser) and suitable as a minimal PWA/demo or starter for a small personal finance UI.

Key characteristics
- Single-file HTML app: index.html contains markup, styles, and JavaScript.
- Persistent data: uses a `window.storage` API to persist JSON blobs keyed as `incomes`, `expenses`, and `recurring`. If `window.storage` is not available in your runtime, see the notes below.
- Export: CSV export of records is provided.

Features
- Add, edit, and delete income and expense records
- Track recurring items (loans, utilities, subscriptions) and log payments
- Dashboard summary (total income, total expenses, net savings)
- CSV export for offline analysis
- Keyboard shortcut: press `n` to open the Add page

Quick links
- Live UI: open `index.html` in any modern browser
- Main file: `index.html`

Table of contents
- Quick start
- Usage
- Developer notes
- Data model
- Contributing
- License

---

## Quick start

1. Clone the repository:

   git clone https://github.com/jimskin03/expense-tracker-app.git
   cd expense-tracker-app

2. Open the app
- Option A (recommended for local testing): start a simple HTTP server and open the app in the browser:

  python -m http.server 8000
  # then visit http://localhost:8000 in your browser

  or

  npx serve .

- Option B: open the file directly in the browser: double-click `index.html` or open it via `file://` URL. (Some browsers restrict certain APIs for file URLs; using a simple HTTP server avoids that.)

3. Start using it: Add income and expense records from the Add tab, view activity on the Records tab, and manage recurring payments on the Recurring tab.

## Usage (summary)
- Records tab: shows the combined activity feed and dashboard (Income / Expenses / Net Savings).
- Add tab: add Income or Expense records. For select lists with an "Others" option you can provide a custom description.
- Recurring tab: create recurring items (Loan, Utilities, Others). You can "Log payment" for a recurring item to add it as an expense for today.
- Export CSV: click Export CSV on the Records page to download a CSV of all records.

See `docs/USAGE.md` for a step-by-step guide with screenshots (if you add them) and common troubleshooting notes.

## Developer notes

This is a minimal single-file SPA. The entire app lives in `index.html`. Major responsibilities are organized roughly as follows:

- Styling: CSS variables at the top of the file (`:root`) control theme colors, radii, and layout.
- State: three in-memory arrays `incomes`, `expenses`, and `recurring` hold application data while running.
- Persistence: `window.storage.get(name)` and `window.storage.set(name, value)` are used to persist data as JSON. The app expects these functions to return/store objects with a `.value` field on `.get()` (see code). If your environment does not provide `window.storage`, replace these calls with `localStorage` or another persistent adapter.
- Rendering: `renderActivityFeed`, `renderDashboard`, and `renderRecurringList` are responsible for UI rendering from state.
- Actions: functions like `addIncome`, `addExpense`, `saveRecurring`, `editRecord`, `deleteRecord`, `logRecurringPayment` implement user interactions.

If you plan to expand the project, consider splitting the JavaScript into modules, adding a build step, and replacing the inline styles with a component-based approach.

## Data model

The app stores three top-level JSON arrays as strings in storage:

- incomes: [{ type: 'income', date: 'YYYY-MM-DD', source: string, amount: number }, ...]
- expenses: [{ type: 'expense', date: 'YYYY-MM-DD', category: string, desc: string, amount: number }, ...]
- recurring: [{ id: 'r_<timestamp>_<random>', type: 'Loan'|'Utilities'|'Others', name: string, amount: number }, ...]

CSV exports produce rows: Type, Date, Category/Source, Description, Amount.

## Runtime / Compatibility notes

- The app is a static HTML file and works in modern Chromium/Firefox/Safari browsers.
- The code uses `window.storage.get` / `window.storage.set`. This is not a standard browser API. If running in a plain browser, provide a tiny polyfill in the console or modify the app to use `localStorage`. Example polyfill (quick):

  // Run in the page console before interacting with the app, or embed in index.html
  window.storage = {
    async get(key){
      const v = localStorage.getItem(key);
      return v ? { value: v } : null;
    },
    async set(key, value){
      localStorage.setItem(key, value);
    }
  };

- If you deploy to GitHub Pages, the app will be served statically. Enable Pages in the repository settings and set the deployment branch to `main` and the folder to `/`.

---

## Contributing
See `docs/CONTRIBUTING.md` for contribution guidelines. The project is intentionally small and opinions are light: keep changes minimal, prefer readability over micro-optimizations, and add tests or manual test plans for new features.

## License
This repository is licensed under the MIT License (see `LICENSE`).
