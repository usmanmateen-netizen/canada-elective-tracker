// Supabase connection for cloud sync + PIN access.
// Fill both values (Supabase dashboard → Project Settings → API), then commit and push.
// The anon key is a publishable key — safe to commit. The PIN is NOT stored here;
// it lives hashed in the database (see setup.sql).
window.TRACKER_CONFIG = {
  url: "",      // e.g. "https://abcdefgh.supabase.co"
  anonKey: "",  // the "anon / public" API key
};
