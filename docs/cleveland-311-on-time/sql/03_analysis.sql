-- ============================================================
-- Cleveland 311: on-time analysis (SQLite)
-- On time = closed on or before the target date.
-- Included: closed requests with a target date, excluding
--           915 rows closed before requested (data issue).
-- Ward = 2026 ward boundaries.
-- ============================================================

-- A1: Overall on-time %
-- Result: 179,842 requests, 68.1% on time
WITH valid AS (
  SELECT *, CASE WHEN closed_at <= target_at THEN 1 ELSE 0 END AS on_time
  FROM requests_clean
  WHERE closed_at IS NOT NULL AND target_at IS NOT NULL
    AND closed_at >= requested_at
)
SELECT COUNT(*) AS requests,
       ROUND(100.0 * SUM(on_time) / COUNT(*), 1) AS on_time_pct
FROM valid;

-- A2: On-time % by agency
WITH valid AS (
  SELECT *, CASE WHEN closed_at <= target_at THEN 1 ELSE 0 END AS on_time
  FROM requests_clean
  WHERE closed_at IS NOT NULL AND target_at IS NOT NULL
    AND closed_at >= requested_at
)
SELECT agency, COUNT(*) AS requests,
       ROUND(100.0 * SUM(on_time) / COUNT(*), 1) AS on_time_pct
FROM valid
GROUP BY agency
ORDER BY on_time_pct;

-- A3: On-time % by ward (2026 boundaries)
WITH valid AS (
  SELECT *, CASE WHEN closed_at <= target_at THEN 1 ELSE 0 END AS on_time
  FROM requests_clean
  WHERE closed_at IS NOT NULL AND target_at IS NOT NULL
    AND closed_at >= requested_at AND ward IS NOT NULL
)
SELECT ward, COUNT(*) AS requests,
       ROUND(100.0 * SUM(on_time) / COUNT(*), 1) AS on_time_pct
FROM valid
GROUP BY ward
ORDER BY on_time_pct;

-- A4: 10 lowest on-time request types (at least 100 requests)
WITH valid AS (
  SELECT *, CASE WHEN closed_at <= target_at THEN 1 ELSE 0 END AS on_time
  FROM requests_clean
  WHERE closed_at IS NOT NULL AND target_at IS NOT NULL
    AND closed_at >= requested_at
)
SELECT request_type, agency, COUNT(*) AS requests,
       ROUND(100.0 * SUM(on_time) / COUNT(*), 1) AS on_time_pct
FROM valid
GROUP BY request_type, agency
HAVING COUNT(*) >= 100
ORDER BY on_time_pct
LIMIT 10;

-- A5: Average days to close vs. average target window, by agency
SELECT agency, COUNT(*) AS closed_requests,
       ROUND(AVG(julianday(closed_at) - julianday(requested_at)), 1) AS avg_days_to_close,
       ROUND(AVG(julianday(target_at) - julianday(requested_at)), 1) AS avg_days_allowed
FROM requests_clean
WHERE closed_at IS NOT NULL AND closed_at >= requested_at
GROUP BY agency
ORDER BY avg_days_to_close DESC;

-- A6: On-time % by year, January to September only (fair comparison)
-- Result: 2024 53.2%, 2025 65.6%, 2026 73.6%
WITH valid AS (
  SELECT *, CASE WHEN closed_at <= target_at THEN 1 ELSE 0 END AS on_time
  FROM requests_clean
  WHERE closed_at IS NOT NULL AND target_at IS NOT NULL
    AND closed_at >= requested_at
)
SELECT strftime('%Y', requested_at) AS year,
       COUNT(*) AS requests,
       ROUND(100.0 * SUM(on_time) / COUNT(*), 1) AS on_time_pct
FROM valid
WHERE strftime('%m', requested_at) BETWEEN '01' AND '09'
GROUP BY year
ORDER BY year;

-- A7: Open requests already past their target date
-- (not counted in the on-time rate, which uses closed requests only)
-- Result: 2,689 as of 2026-10-23
SELECT COUNT(*) AS open_past_target
FROM requests_clean
WHERE closed_at IS NULL
  AND target_at < '2026-10-23';
