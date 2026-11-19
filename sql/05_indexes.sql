-- Phase 4: Netflix workload indexes

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;

SET search_path TO netflix;

-- R01: Supports the latest unfinished viewing per profile and title.
-- Equality columns first, then descending timestamp; partial index excludes completed views.
CREATE INDEX IF NOT EXISTS idx_va_unfinished_profile_title_time
ON viewing_activity (profile_id, title_id, started_at DESC)
INCLUDE (episode_id, duration_watched_sec)
WHERE completed = FALSE;

-- R05: Trigram index supports substring searches such as ILIKE '%love%'.
CREATE INDEX IF NOT EXISTS idx_titles_name_trgm
ON titles USING GIN (name public.gin_trgm_ops);

-- R10: Matches the exact lower(email) expression in the sign-in query.
CREATE INDEX IF NOT EXISTS idx_accounts_lower_email
ON accounts (lower(email));

-- R11: Partial covering B-tree index for R11's failed-invoice lookup.
-- billing_period_start is first for period filtering, followed by account_id
-- for account matching. INCLUDE covers invoice_id and amount_inr.
-- The WHERE clause keeps only FAILED invoices, reducing index size.
CREATE INDEX IF NOT EXISTS idx_invoices_failed_period_account
ON invoices (billing_period_start, account_id)
INCLUDE (invoice_id, amount_inr)
WHERE status = 'FAILED';

-- R19: B-tree index for per-title viewing activity lookups.
-- title_id is first because it is the grouping/equality key;
-- started_at DESC supports retrieving the latest activity efficiently.
-- The seed-data planner chose Seq Scan + HashAggregate instead.

CREATE INDEX IF NOT EXISTS idx_va_title_started
ON viewing_activity (title_id, started_at DESC);

-- R21: Partial B-tree index for overdue billing-date lookups on ON_HOLD accounts.
-- next_billing_date is the indexed range/filter column.
-- The partial WHERE clause excludes accounts with other statuses,
-- keeping the index smaller and focused on this query.
CREATE INDEX IF NOT EXISTS idx_accounts_hold_billing_date
ON accounts (next_billing_date)
WHERE status = 'ON_HOLD';

-- R22: Partial B-tree index for filtering titles by leaving date.
-- leaving_on is the indexed date column used by the query.
-- The WHERE clause excludes NULL leaving dates, avoiding unnecessary index entries.

CREATE INDEX IF NOT EXISTS idx_titles_leaving_on
ON titles (leaving_on)
WHERE leaving_on IS NOT NULL;

-- R23: Covering B-tree index for newest-first viewing activity retrieval.
-- started_at DESC matches the query's sorting order.
-- INCLUDE stores view_id, profile_id, title_id and episode_id
-- so the query can potentially be served without fetching table rows.

CREATE INDEX IF NOT EXISTS idx_va_started_desc_cover
ON viewing_activity (started_at DESC)
INCLUDE (view_id, profile_id, title_id, episode_id);

-- R24: Covering composite B-tree index for profile lookup by account.
-- account_id comes first for equality filtering; created_at comes second
-- to support ordering profiles by creation time within an account.
-- INCLUDE covers profile_name, is_kids and maturity_limit.
CREATE INDEX IF NOT EXISTS idx_profiles_account_created
ON profiles (account_id, created_at)
INCLUDE (profile_name, is_kids, maturity_limit);

-- R25: Composite B-tree index for joining title_genres by genre.
-- genre_id comes first because the query filters/joins using the genre;
-- title_id follows to retrieve the associated titles.
CREATE INDEX IF NOT EXISTS idx_title_genres_genre_title
ON title_genres (genre_id, title_id);

ANALYZE netflix.viewing_activity;
ANALYZE netflix.titles;
ANALYZE netflix.accounts;
ANALYZE netflix.invoices;
ANALYZE netflix.profiles;
ANALYZE netflix.title_genres;
