// Connect the app to your Supabase project (see SETUP.md, step 3).
// Both values come from Supabase > Project Settings > API Keys.
// The publishable/anon key is designed to be public: the database rules
// in supabase/schema.sql are what keep each person's data private.
// Leave both empty to use the app on one device without accounts.
window.GCSE_CONFIG = {
  supabaseUrl: "",      // e.g. "https://abcdefghijkl.supabase.co"
  supabaseAnonKey: ""   // the publishable key (sb_publishable_...) or the legacy anon key
};
