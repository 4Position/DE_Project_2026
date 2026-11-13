
-- ============================================================
-- PROJECT : Netflix Streaming Database
-- FILE    : 01_schema.sql
-- PURPOSE : Create all 11 relational tables for Phase 2
-- SCHEMA  : netflix
-- ============================================================

CREATE SCHEMA IF NOT EXISTS netflix;

SET search_path TO netflix;

-- ============================================================
-- 1. PLANS
-- Parent table for accounts
-- ============================================================

CREATE TABLE plans (
    plan_id             INTEGER PRIMARY KEY,
    plan_name           VARCHAR(20) NOT NULL UNIQUE,
    monthly_price_inr   NUMERIC(10,2) NOT NULL
                            CHECK (monthly_price_inr >= 0),
    max_streams         SMALLINT NOT NULL
                            CHECK (max_streams > 0),
    max_resolution      VARCHAR(10) NOT NULL
                            CHECK (max_resolution IN
                                ('480p', '720p', '1080p', '4K')),
    has_ads             BOOLEAN NOT NULL
);

-- ============================================================
-- 2. ACCOUNTS
-- References plans
-- ============================================================

CREATE TABLE accounts (
    account_id          INTEGER PRIMARY KEY,
    email               VARCHAR(254) NOT NULL UNIQUE,
    phone               VARCHAR(20) UNIQUE,
    country_code        CHAR(2) NOT NULL
                            CHECK (country_code IN ('IN', 'AE', 'SG')),
    plan_id             INTEGER NOT NULL,
    signup_date         DATE NOT NULL,
    status              VARCHAR(20) NOT NULL
                            CHECK (status IN
                                ('ACTIVE', 'CANCELLED', 'ON_HOLD')),
    cancelled_on        DATE,
    next_billing_date   DATE,

    CONSTRAINT fk_accounts_plan
        FOREIGN KEY (plan_id)
        REFERENCES plans(plan_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_account_billing_status
        CHECK (
            (status = 'CANCELLED'
                AND cancelled_on IS NOT NULL
                AND next_billing_date IS NULL)
            OR
            (status IN ('ACTIVE', 'ON_HOLD')
                AND cancelled_on IS NULL
                AND next_billing_date IS NOT NULL)
        )
);

-- ============================================================
-- 3. PROFILES
-- References accounts
-- ============================================================

CREATE TABLE profiles (
    profile_id      INTEGER PRIMARY KEY,
    account_id      INTEGER NOT NULL,
    profile_name    VARCHAR(50) NOT NULL,
    is_kids         BOOLEAN NOT NULL,
    maturity_limit  VARCHAR(10) NOT NULL,
    language        VARCHAR(30) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_profiles_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_profile_maturity
        CHECK (
            (is_kids = TRUE
                AND maturity_limit IN ('U', 'UA7'))
            OR
            (is_kids = FALSE
                AND maturity_limit IN ('A', 'UA13', 'UA16'))
        )
);

-- ============================================================
-- 4. GENRES
-- Parent table for title_genres
-- ============================================================

CREATE TABLE genres (
    genre_id    INTEGER PRIMARY KEY,
    genre_name  VARCHAR(40) NOT NULL UNIQUE
);

-- ============================================================
-- 5. TITLES
-- Parent table for episodes, title_genres and activity tables
-- ============================================================

CREATE TABLE titles (
    title_id            INTEGER PRIMARY KEY,
    title_type          VARCHAR(10) NOT NULL
                            CHECK (title_type IN ('MOVIE', 'SERIES')),
    name                VARCHAR(255) NOT NULL,
    release_year        SMALLINT NOT NULL
                            CHECK (release_year BETWEEN 1888 AND 2100),
    maturity_rating     VARCHAR(10) NOT NULL
                            CHECK (maturity_rating IN
                                ('U', 'UA7', 'UA13', 'UA16', 'A')),
    original_language   VARCHAR(30) NOT NULL,
    runtime_min         SMALLINT,
    is_netflix_original BOOLEAN NOT NULL,
    added_on            DATE NOT NULL,
    leaving_on          DATE,

    CONSTRAINT chk_title_runtime
        CHECK (
            (title_type = 'MOVIE' AND runtime_min IS NOT NULL
                AND runtime_min > 0)
            OR
            (title_type = 'SERIES' AND runtime_min IS NULL)
        ),

    CONSTRAINT chk_title_leaving_date
        CHECK (leaving_on IS NULL OR leaving_on >= added_on),

    CONSTRAINT chk_originals_never_leave
        CHECK (NOT is_netflix_original OR leaving_on IS NULL)
);

-- ============================================================
-- 6. TITLE_GENRES
-- Bridge table: titles <-> genres (M:N)
-- ============================================================

CREATE TABLE title_genres (
    title_id    INTEGER NOT NULL,
    genre_id    INTEGER NOT NULL,

    PRIMARY KEY (title_id, genre_id),

    CONSTRAINT fk_title_genres_title
        FOREIGN KEY (title_id)
        REFERENCES titles(title_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_title_genres_genre
        FOREIGN KEY (genre_id)
        REFERENCES genres(genre_id)
        ON DELETE CASCADE
);

-- ============================================================
-- 7. EPISODES
-- References titles (series)
-- ============================================================

CREATE TABLE episodes (
    episode_id      INTEGER PRIMARY KEY,
    title_id        INTEGER NOT NULL,
    season_no       SMALLINT NOT NULL CHECK (season_no > 0),
    episode_no      SMALLINT NOT NULL CHECK (episode_no > 0),
    episode_title   VARCHAR(255) NOT NULL,
    runtime_min     SMALLINT NOT NULL CHECK (runtime_min > 0),
    release_date    DATE NOT NULL,

    CONSTRAINT uq_episode_position
        UNIQUE (title_id, season_no, episode_no),

    -- Required as the target of the composite FK in viewing_activity.
    CONSTRAINT uq_episode_title_pair
        UNIQUE (episode_id, title_id),

    CONSTRAINT fk_episodes_title
        FOREIGN KEY (title_id)
        REFERENCES titles(title_id)
        ON DELETE RESTRICT
);

-- ============================================================
-- 8. VIEWING_ACTIVITY
-- References profiles, titles and optionally episodes
-- ============================================================

CREATE TABLE viewing_activity (
    view_id                 INTEGER PRIMARY KEY,
    profile_id              INTEGER NOT NULL,
    title_id                INTEGER NOT NULL,
    episode_id              INTEGER,
    started_at              TIMESTAMPTZ NOT NULL,
    duration_watched_sec    INTEGER NOT NULL
                                CHECK (duration_watched_sec > 0),
    device_type             VARCHAR(10) NOT NULL
                                CHECK (device_type IN
                                    ('TV', 'MOBILE', 'TABLET', 'LAPTOP')),
    completed               BOOLEAN NOT NULL,

    CONSTRAINT fk_viewing_profile
        FOREIGN KEY (profile_id)
        REFERENCES profiles(profile_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_viewing_title
        FOREIGN KEY (title_id)
        REFERENCES titles(title_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_viewing_episode
        FOREIGN KEY (episode_id, title_id)
        REFERENCES episodes(episode_id, title_id)
        ON DELETE RESTRICT
);

-- ============================================================
-- 9. RATINGS
-- Bridge table: profiles <-> titles (M:N)
-- ============================================================

CREATE TABLE ratings (
    profile_id  INTEGER NOT NULL,
    title_id    INTEGER NOT NULL,
    rating      VARCHAR(20) NOT NULL
                    CHECK (rating IN
                        ('THUMBS_UP', 'THUMBS_DOWN', 'LOVE')),
    rated_at    TIMESTAMPTZ NOT NULL,

    PRIMARY KEY (profile_id, title_id),

    CONSTRAINT fk_ratings_profile
        FOREIGN KEY (profile_id)
        REFERENCES profiles(profile_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_ratings_title
        FOREIGN KEY (title_id)
        REFERENCES titles(title_id)
        ON DELETE RESTRICT
);

-- ============================================================
-- 10. MY_LIST
-- Bridge table: profiles <-> titles (M:N)
-- ============================================================

CREATE TABLE my_list (
    profile_id  INTEGER NOT NULL,
    title_id    INTEGER NOT NULL,
    added_at    TIMESTAMPTZ NOT NULL,

    PRIMARY KEY (profile_id, title_id),

    CONSTRAINT fk_my_list_profile
        FOREIGN KEY (profile_id)
        REFERENCES profiles(profile_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_my_list_title
        FOREIGN KEY (title_id)
        REFERENCES titles(title_id)
        ON DELETE RESTRICT
);

-- ============================================================
-- 11. INVOICES
-- References accounts
-- ============================================================

CREATE TABLE invoices (
    invoice_id          INTEGER PRIMARY KEY,
    account_id          INTEGER NOT NULL,
    billing_period_start DATE NOT NULL,
    amount_inr          NUMERIC(10,2) NOT NULL
                            CHECK (amount_inr >= 0),
    status              VARCHAR(10) NOT NULL
                            CHECK (status IN
                                ('PAID', 'FAILED', 'REFUNDED')),
    paid_at             TIMESTAMPTZ,

    CONSTRAINT uq_invoice_account_period
        UNIQUE (account_id, billing_period_start),

    CONSTRAINT chk_invoice_billing_day
        CHECK (EXTRACT(DAY FROM billing_period_start) = 1),

    CONSTRAINT chk_invoice_payment_status
        CHECK (
            (status = 'FAILED' AND paid_at IS NULL)
            OR
            (status IN ('PAID', 'REFUNDED') AND paid_at IS NOT NULL)
        ),

    CONSTRAINT fk_invoices_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
        ON DELETE RESTRICT
);

-- ============================================================
-- END OF SCHEMA CREATION
-- ============================================================
