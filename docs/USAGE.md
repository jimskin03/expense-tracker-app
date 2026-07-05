# Usage guide — Ledger (expense-tracker-app)

This document explains how to use the app from a user's perspective and includes tips and troubleshooting.

1. Opening the app
- Serve the project with a simple HTTP server and open http://localhost:8000/index.html, or open index.html directly.

2. Recording income
- Go to the Add tab.
- Under Income, choose a date (defaults to today if left empty), select a Source (or choose "Others" and write your own), and enter the Amount (RM).
- Click "Add income". The app saves the entry and returns you to the Records page.

3. Recording an expense
- Go to the Add tab.
- Under Expense, choose a date (defaults to today if left empty), pick a Category (or choose "Others" and specify), optionally provide a Description, and enter the Amount (RM).
- Click "Add expense".

4. Editing and deleting records
- On the Records tab, each activity item has Edit and Delete buttons.
- Edit: moves the selected entry back to the Add page with fields pre-filled. When you save, the previous entry is removed and the new one is saved (simple edit flow).
- Delete: removes the record after confirmation.

5. Recurring transactions
- Go to the Recurring tab.
- Add a recurring entry by selecting a Type (Loan, Utilities, Others), giving it a Name and Amount, then click "Add recurring".
- Each recurring item can be "Logged" which creates an expense record with today's date and the recurring amount.

6. Exporting CSV
- From the Records page, click "Export CSV" to download a CSV containing all Income and Expense records.

7. Keyboard shortcuts
- Press `n` to open the Add page quickly.

Troubleshooting
- If records do not persist after reload, your runtime may not expose `window.storage` as expected. Add the `localStorage` polyfill from the README or modify the storage functions inside `index.html` to use `localStorage` directly.
- If the CSV does not download, ensure pop-ups are allowed and you are running in a standard browser environment (not a restricted iframe).

Feedback and feature requests
- Open an issue on the repo with detailed steps to reproduce and the expected result.
