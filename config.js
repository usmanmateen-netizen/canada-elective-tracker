// Supabase connection for cloud sync + PIN access.
// Dedicated project in your personal org (separate from examloop).
// The anon key is a publishable key, protected by row-level security — safe to commit.
// The PIN is NOT here; it lives hashed in the database (see setup.sql).
window.TRACKER_CONFIG = {
  url: "https://iqpwyiiltchrrnxdfaxm.supabase.co",
  anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxcHd5aWlsdGNocnJueGRmYXhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMyNDE2NTgsImV4cCI6MjA5ODgxNzY1OH0.I5L-X6YlQJz7DRigiMKClbNvI9_lFXFlPJ8aC2RAiJw",
};
