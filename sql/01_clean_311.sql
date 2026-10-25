-- ============================================================
-- Cleveland 311: clean raw import into requests_clean (SQLite)
-- Input:  raw_311 (CSV imported as-is by DB Browser, all text)
-- ============================================================

-- STEP 1: Build a clean table with simple column names,
--         trimmed text, and blanks turned into real NULLs.
DROP TABLE IF EXISTS requests_clean;

CREATE TABLE requests_clean AS
SELECT
  NULLIF(TRIM("Reference Number"), '')          AS reference_number,
  NULLIF(TRIM("Service Category"), '')          AS service_category,
  NULLIF(TRIM("Service Request Type"), '')      AS request_type,
  NULLIF(TRIM("Responsible Agency"), '')        AS agency,
  NULLIF(TRIM("Responsible Division"), '')      AS division,
  NULLIF(TRIM("Status"), '')                    AS status,
  NULLIF(TRIM("Requested Date and Time"), '')   AS requested_at,
  NULLIF(TRIM("Closed Date"), '')               AS closed_at,
  NULLIF(TRIM("Target Date"), '')               AS target_at,
  NULLIF(TRIM("Request Source"), '')            AS source,
  NULLIF(TRIM("Neighborhood"), '')              AS neighborhood,
  CAST(NULLIF(TRIM("Ward"), '') AS INTEGER)     AS ward,
  CAST(NULLIF(TRIM("Latitude"), '') AS REAL)    AS latitude,
  CAST(NULLIF(TRIM("Longitude"), '') AS REAL)   AS longitude
FROM raw_311;

-- STEP 2: Convert dates from  10/23/2026 11:55:19 PM
--         to ISO format       2026-10-23 23:55:19
--         (SQLite date math only works on ISO dates)
-- A CTE splits each date into parts, then UPDATE rebuilds it.
-- Run the same pattern for each of the 3 date columns.

UPDATE requests_clean SET requested_at = (
  WITH p AS (
    SELECT requested_at AS d,
           substr(requested_at, instr(requested_at, '/') + 1) AS r1
  ), q AS (
    SELECT d,
      CAST(substr(d, 1, instr(d, '/') - 1) AS INTEGER)          AS mon,
      CAST(substr(r1, 1, instr(r1, '/') - 1) AS INTEGER)        AS dy,
      substr(r1, instr(r1, '/') + 1)                            AS r2
    FROM p
  ), t AS (
    SELECT mon, dy,
      CAST(substr(r2, 1, 4) AS INTEGER)                         AS yr,
      substr(r2, 6)                                             AS tm
    FROM q
  )
  SELECT printf('%04d-%02d-%02d %02d:%s', yr, mon, dy,
           CASE
             WHEN substr(tm, -2) = 'AM' AND CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER) = 12 THEN 0
             WHEN substr(tm, -2) = 'PM' AND CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER) <> 12
                  THEN CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER) + 12
             ELSE CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER)
           END,
           substr(tm, instr(tm, ':') + 1, 5))
  FROM t
)
WHERE requested_at LIKE '%/%';

UPDATE requests_clean SET closed_at = (
  WITH p AS (
    SELECT closed_at AS d,
           substr(closed_at, instr(closed_at, '/') + 1) AS r1
  ), q AS (
    SELECT d,
      CAST(substr(d, 1, instr(d, '/') - 1) AS INTEGER)          AS mon,
      CAST(substr(r1, 1, instr(r1, '/') - 1) AS INTEGER)        AS dy,
      substr(r1, instr(r1, '/') + 1)                            AS r2
    FROM p
  ), t AS (
    SELECT mon, dy,
      CAST(substr(r2, 1, 4) AS INTEGER)                         AS yr,
      substr(r2, 6)                                             AS tm
    FROM q
  )
  SELECT printf('%04d-%02d-%02d %02d:%s', yr, mon, dy,
           CASE
             WHEN substr(tm, -2) = 'AM' AND CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER) = 12 THEN 0
             WHEN substr(tm, -2) = 'PM' AND CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER) <> 12
                  THEN CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER) + 12
             ELSE CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER)
           END,
           substr(tm, instr(tm, ':') + 1, 5))
  FROM t
)
WHERE closed_at LIKE '%/%';

UPDATE requests_clean SET target_at = (
  WITH p AS (
    SELECT target_at AS d,
           substr(target_at, instr(target_at, '/') + 1) AS r1
  ), q AS (
    SELECT d,
      CAST(substr(d, 1, instr(d, '/') - 1) AS INTEGER)          AS mon,
      CAST(substr(r1, 1, instr(r1, '/') - 1) AS INTEGER)        AS dy,
      substr(r1, instr(r1, '/') + 1)                            AS r2
    FROM p
  ), t AS (
    SELECT mon, dy,
      CAST(substr(r2, 1, 4) AS INTEGER)                         AS yr,
      substr(r2, 6)                                             AS tm
    FROM q
  )
  SELECT printf('%04d-%02d-%02d %02d:%s', yr, mon, dy,
           CASE
             WHEN substr(tm, -2) = 'AM' AND CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER) = 12 THEN 0
             WHEN substr(tm, -2) = 'PM' AND CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER) <> 12
                  THEN CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER) + 12
             ELSE CAST(substr(tm, 1, instr(tm, ':') - 1) AS INTEGER)
           END,
           substr(tm, instr(tm, ':') + 1, 5))
  FROM t
)
WHERE target_at LIKE '%/%';

-- STEP 3: Validate the cleaning
SELECT COUNT(*) AS total_rows FROM requests_clean;
SELECT requested_at, closed_at, target_at FROM requests_clean LIMIT 5;
SELECT COUNT(*) AS bad_dates FROM requests_clean
WHERE requested_at NOT LIKE '____-__-__ __:__:__';
