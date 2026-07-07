# Ledger — Expense Tracker (expense-tracker-app)

A lightweight, single-file web app to track income, expenses, and recurring payments with visual analytics. Designed to be locally hosted (open index.html in a browser) and suitable as a minimal PWA/demo or starter template.

## Key characteristics
- **Single-file HTML app**: index.html contains markup, styles, and JavaScript.
- **Persistent data**: uses a `window.storage` API to persist JSON blobs keyed as `incomes`, `expenses`, and `recurring`. If `window.storage` is not available in your runtime, see the notes below.
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

3. Start using it: Add income and expense records from the Add tab, view activity on the Records tab, and manage recurring payments on the Recurring tab.

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
- **Persistence**: `window.storage.get(name)` and `window.storage.set(name, value)` are used to persist data as JSON. The app expects these functions to return/store objects with a `.value` field on get.
- **Rendering**: 
  - `renderActivityFeed()`: displays activity feed with optional date filtering
  - `renderDashboard()`: updates dashboard totals
  - `renderRecurringList()`: displays recurring items
  - `renderChart()`: creates/updates doughnut chart and legend
- **Filtering**: 
  - `getFilteredExpenses()`: returns expenses matching the active date filter
  - `groupByCategory()`: aggregates expenses by category for charting
  - `setupFilterListeners()`: sets up date filter button handlers
- **Actions**: functions like `addIncome`, `addExpense`, `saveRecurring`, `editRecord`, `deleteRecord`, `logRecurringPayment` implement user interactions.

### Adding New Features

If you plan to expand the project, consider:
- Splitting the JavaScript into modules for easier maintenance
- Adding a build step for minification
- Replacing inline styles with a component-based approach
- Adding unit tests for core calculation functions

## Data model

The app stores three top-level JSON arrays as strings in storage:

```javascript
// incomes: array of income records
incomes = [
  {
    type: 'income',
    date: 'YYYY-MM-DD',
    source: string,
    amount: number
  },
  ...
];

// expenses: array of expense records
expenses = [
  {
    type: 'expense',
    date: 'YYYY-MM-DD',
    category: string,
    desc: string,        // optional description
    amount: number
  },
  ...
];

// recurring: array of recurring items
recurring = [
  {
    id: 'r_<timestamp>_<random>',
    type: 'Loan' | 'Utilities' | 'Others',
    name: string,
    amount: number
  },
  ...
];
```

CSV exports produce rows: `Type, Date, Category/Source, Description, Amount`.

## Runtime / Compatibility notes

- The app is a static HTML file and works in modern Chromium/Firefox/Safari browsers.
- The code uses `window.storage.get` / `window.storage.set`. This is not a standard browser API. If running in a plain browser, provide a polyfill:

  ```javascript
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
  ```

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
