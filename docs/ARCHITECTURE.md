# Architecture notes — Ledger (expense-tracker-app)

This app is intentionally minimal: a single-file SPA implemented in `index.html`. The following outlines the internal structure and the responsibilities of the major code sections.

1. Top-level structure (in index.html)
- CSS variables and theme — top of the `<head>` inside a `<style>` block.
- HTML markup — three main pages (Records, Add, Recurring) toggled by JS using the `.page` and `.active` classes.
- JavaScript — enclosed in a single `<script>` block near the bottom of the file.

2. JavaScript organization (logical sections)
- State & persistence: `let incomes = []; let expenses = []; let recurring = [];` and functions `loadAll`, `saveIncomes`, `saveExpenses`, `saveRecurringList` that use `window.storage`.
- UI/navigation: `showPage` toggles pages and active nav tab.
- Form handling: `addIncome`, `addExpense`, `clearIncomeForm`, `clearExpenseForm`.
- Editing & deletion: `editRecord`, `deleteRecord` (both types), which manipulate arrays and save.
- Recurring: `saveRecurring`, `editRecurring`, `deleteRecurring`, `logRecurringPayment`.
- Rendering: `renderActivityFeed`, `renderDashboard`, `renderRecurringList`.
- Utilities: `escapeHtml`, `exportCSV`, `todayStr`, helper functions for badges and categories.

3. Storage contract
- The app calls `await window.storage.get('incomes')` and expects either `null` or an object with `.value` containing the JSON string. The `set` call is `await window.storage.set('incomes', JSON.stringify(incomes))`.
- If you port the app to a different runtime, implement this contract or change calls to `localStorage`.

4. Suggested refactors
- Split JS into modules and introduce a build system (Vite/Parcel/ESBuild) if the app grows.
- Introduce a small adapter for storage (wrap `localStorage`, `indexedDB`, browser extension storage, or an API) and inject it at load time.
- Add unit tests around data manipulation functions and an end-to-end test for the user flows.

5. Security & privacy
- All data is stored locally in the browser. If you add a server or sync service, ensure data is encrypted in transit and at rest as appropriate.

6. Extensibility points
- Import/backup: add CSV/JSON import.
- Sync: add optional sync using a user-provided backend or third-party storage providers.
- Reports: monthly summaries, charts, category breakdowns.
