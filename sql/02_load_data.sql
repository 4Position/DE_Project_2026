
-- ============================================================
-- PROJECT : Netflix Streaming Database
-- FILE    : 02_load_data.sql
-- PURPOSE : Load all 11 seed CSV files
-- ============================================================

BEGIN;

SET search_path TO netflix;

-- 1. PLANS
\copy netflix.plans FROM 'seed_data/plans.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 2. ACCOUNTS
\copy netflix.accounts FROM 'seed_data/accounts.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 3. PROFILES
\copy netflix.profiles FROM 'seed_data/profiles.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 4. GENRES
\copy netflix.genres FROM 'seed_data/genres.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 5. TITLES
\copy netflix.titles FROM 'seed_data/titles.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 6. TITLE_GENRES
\copy netflix.title_genres FROM 'seed_data/title_genres.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 7. EPISODES
\copy netflix.episodes FROM 'seed_data/episodes.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 8. VIEWING_ACTIVITY
\copy netflix.viewing_activity FROM 'seed_data/viewing_activity.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 9. RATINGS
\copy netflix.ratings FROM 'seed_data/ratings.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 10. MY_LIST
\copy netflix.my_list FROM 'seed_data/my_list.csv' WITH (FORMAT CSV, HEADER TRUE);

-- 11. INVOICES
\copy netflix.invoices FROM 'seed_data/invoices.csv' WITH (FORMAT CSV, HEADER TRUE);

-- Update PostgreSQL table statistics
ANALYZE;

COMMIT;

-- ============================================================
-- END OF DATA LOADING
-- ============================================================
