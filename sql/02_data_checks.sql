-- ============================================================
-- Cleveland 311: data quality checks (SQLite)
-- Input: requests_clean (built by 01_clean_311.sql)
-- ============================================================

-- CHECK 1: Row count and date range
-- Result: 188,406 rows, 2024-02-28 to 2026-10-23
SELECT COUNT(*)          AS total_rows,
       MIN(requested_at) AS first_request,
       MAX(requested_at) AS last_request
FROM requests_clean;

-- CHECK 2: Missing values in key columns
-- Result: 4,192 no closed date (open), 3,660 no target date,
--         429 no ward, 0 no agency
SELECT
  SUM(closed_at IS NULL) AS no_closed_date,
  SUM(target_at IS NULL) AS no_target_date,
  SUM(ward IS NULL)      AS no_ward,
  SUM(agency IS NULL)    AS no_agency
FROM requests_clean;

-- CHECK 3: Duplicate reference numbers
-- Result: 0 duplicates
SELECT reference_number, COUNT(*) AS times
FROM requests_clean
GROUP BY reference_number
HAVING COUNT(*) > 1
ORDER BY times DESC;

-- CHECK 4: Impossible dates (closed before requested)
-- Result: 915 rows
SELECT COUNT(*) AS closed_before_requested
FROM requests_clean
WHERE closed_at < requested_at;

-- CHECK 4b: Which agencies have impossible dates?
-- Result: Public Works 567, Parks & Recreation 348
SELECT agency, COUNT(*) AS bad_rows
FROM requests_clean
WHERE closed_at < requested_at
GROUP BY agency
ORDER BY bad_rows DESC;

-- CHECK 4c: Which channel, and how far apart?
-- Result: 739 of 915 from inbound calls; about 2 hours apart
SELECT source, COUNT(*) AS bad_rows,
       ROUND(AVG((julianday(requested_at) - julianday(closed_at)) * 24), 1) AS avg_hours_early
FROM requests_clean
WHERE closed_at < requested_at
GROUP BY source
ORDER BY bad_rows DESC;

-- CHECK 5: Does status agree with closed date?
-- Result: consistent (all Closed have a closed date, no Open does)
SELECT status,
       SUM(closed_at IS NULL)     AS no_close_date,
       SUM(closed_at IS NOT NULL) AS has_close_date
FROM requests_clean
GROUP BY status;
