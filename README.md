# Canada Elective Tracker

Application tracker for Canadian visiting electives, tailored to a Norwich Medical School (UEA) student. Static site (GitHub Pages) + Supabase for saved progress behind a PIN.

## Setup (one time)
1. **Database**: Supabase dashboard → SQL Editor → paste `setup.sql` → replace `CHOOSE-A-PIN` with the real PIN → Run.
2. **Connect the site**: put the project URL and anon key into `config.js` (dashboard → Project Settings → API), commit, push.
3. Open the site, enter the PIN. Progress then syncs to Supabase from any device with the PIN.

## How access works
- The table has Row Level Security enabled with no policies, so the REST API cannot read or write it directly.
- The only access is via two database functions (`tracker_get`, `tracker_set`) that require the PIN; the PIN is stored only as a SHA-256 hash.
- The anon key in `config.js` is Supabase's publishable key — committing it is expected.
- Use a PIN of 6+ digits; anyone with the site URL can attempt PINs.
- "Continue without syncing" runs the tracker on local storage only.

## Changing the PIN
Run the `update elective_tracker set pin_hash = ...` statement at the bottom of `setup.sql` with the new PIN.

## Files
- `index.html` — the tracker (all data and drafts embedded; no build step)
- `config.js` — Supabase URL + anon key
- `setup.sql` — database setup
