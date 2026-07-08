# Admin Link Notes

The Flutter app is structured so admin-managed data can come from Supabase-backed tables.

Laravel admin should manage:

- profiles
- helpers/coaches
- groups and members
- community posts and comments
- prayer requests
- reports and safety reviews
- subscriptions and payments
- devotion and recovery-plan content

Flutter should consume admin-approved content through repositories in `data/repositories/`, then swap `MockFreedomRepository` for Supabase-backed implementations.
