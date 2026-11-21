-- ============================================================
-- PHASE 5: RANGE PARTITIONING DEMONSTRATION
-- Table: viewing_activity_partitioned
-- Partition key: started_at
-- Strategy: Monthly RANGE partitions
-- Original viewing_activity remains unchanged.
-- ============================================================

BEGIN;

SET search_path TO netflix;

-- 1. Create partitioned parent table.
-- PostgreSQL requires the partition key (started_at) to be
-- included in a PRIMARY KEY / UNIQUE constraint.

CREATE TABLE viewing_activity_partitioned (
    view_id              INTEGER NOT NULL,
    profile_id           INTEGER NOT NULL,
    title_id             INTEGER NOT NULL,
    episode_id           INTEGER,
    started_at           TIMESTAMPTZ NOT NULL,
    duration_watched_sec INTEGER NOT NULL,
    device_type          VARCHAR(10) NOT NULL,
    completed            BOOLEAN NOT NULL,

    CONSTRAINT viewing_activity_partitioned_pkey
        PRIMARY KEY (view_id, started_at),

    CONSTRAINT viewing_activity_partitioned_duration_check
        CHECK (duration_watched_sec > 0),

    CONSTRAINT viewing_activity_partitioned_device_check
        CHECK (device_type IN ('TV', 'MOBILE', 'TABLET', 'LAPTOP')),

    CONSTRAINT fk_vap_profile
        FOREIGN KEY (profile_id)
        REFERENCES profiles(profile_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_vap_title
        FOREIGN KEY (title_id)
        REFERENCES titles(title_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_vap_episode
        FOREIGN KEY (episode_id, title_id)
        REFERENCES episodes(episode_id, title_id)
        ON DELETE RESTRICT
)
PARTITION BY RANGE (started_at);


-- 2. Create monthly partitions from January 2025
--    through July 2026.
--    Each partition includes its lower boundary and excludes
--    its upper boundary.

DO $$
DECLARE
    month_start DATE := DATE '2025-01-01';
    next_month DATE;
    partition_name TEXT;
BEGIN
    WHILE month_start < DATE '2026-08-01' LOOP
        next_month := (month_start + INTERVAL '1 month')::DATE;

        partition_name := 'viewing_activity_p' ||
                          TO_CHAR(month_start, 'YYYY_MM');

        EXECUTE FORMAT(
            'CREATE TABLE netflix.%I PARTITION OF netflix.viewing_activity_partitioned
             FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            month_start::TEXT || ' 00:00:00+05:30',
            next_month::TEXT || ' 00:00:00+05:30'
        );

        month_start := next_month;
    END LOOP;
END $$;


-- 3. Default partition for dates outside the monthly ranges.

CREATE TABLE viewing_activity_p_default
PARTITION OF viewing_activity_partitioned DEFAULT;


-- 4. Copy the large dataset into the partitioned table.
--    The original table is not modified.

INSERT INTO viewing_activity_partitioned (
    view_id,
    profile_id,
    title_id,
    episode_id,
    started_at,
    duration_watched_sec,
    device_type,
    completed
)
SELECT
    view_id,
    profile_id,
    title_id,
    episode_id,
    started_at,
    duration_watched_sec,
    device_type,
    completed
FROM viewing_activity;


-- 5. Create useful indexes on the partitioned table.
--    PostgreSQL creates corresponding indexes on its partitions.

CREATE INDEX idx_vap_profile_started
ON viewing_activity_partitioned (profile_id, started_at DESC);

CREATE INDEX idx_vap_title_started
ON viewing_activity_partitioned (title_id, started_at DESC);


-- 6. Update planner statistics.

ANALYZE viewing_activity_partitioned;


-- 7. Verify row counts.

SELECT
    (SELECT COUNT(*) FROM viewing_activity) AS original_rows,
    (SELECT COUNT(*) FROM viewing_activity_partitioned) AS partitioned_rows;


-- 8. Show partition pruning for July 2026.

EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM viewing_activity_partitioned
WHERE started_at >= TIMESTAMPTZ '2026-07-01 00:00:00+05:30'
  AND started_at <  TIMESTAMPTZ '2026-08-01 00:00:00+05:30';


-- 9. Show which partitions contain data.

SELECT
    tableoid::regclass AS partition_name,
    COUNT(*) AS rows_in_partition
FROM viewing_activity_partitioned
GROUP BY tableoid
ORDER BY partition_name;

COMMIT;