// Supabase connection for cloud sync + PIN access.
// The anon key is a publishable key, protected by row-level security — safe to commit.
// The PIN is NOT here; it lives hashed in the database (see setup.sql).
window.TRACKER_CONFIG = {
  url: "https://ofhzgsojlytpjhsoequn.supabase.co",
  anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9maHpnc29qbHl0cGpoc29lcXVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMyNTMxMDUsImV4cCI6MjA5ODgyOTEwNX0.FCFhRjihkpiCoq0IUhlivbbZqyY4vm24nmGNk_sbFS8",
};
