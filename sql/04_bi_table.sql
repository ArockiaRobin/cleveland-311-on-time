-- ============================================================
-- Cleveland 311: final table for Power BI (SQLite)
-- Business rules live here, so SQL and Power BI numbers match.
-- Export requests_bi to CSV and load it into Power BI.
-- ============================================================
DROP TABLE IF EXISTS requests_bi;

CREATE TABLE requests_bi AS
SELECT reference_number, service_category, request_type, agency, division,
       status, source, neighborhood, ward, latitude, longitude,
       requested_at, closed_at, target_at,
       CASE WHEN closed_at IS NOT NULL AND target_at IS NOT NULL
             AND closed_at >= requested_at THEN 1 ELSE 0 END AS valid_for_sla,
       CASE WHEN closed_at IS NOT NULL AND target_at IS NOT NULL
             AND closed_at >= requested_at AND closed_at <= target_at
            THEN 1 ELSE 0 END AS on_time,
       CASE WHEN closed_at >= requested_at
            THEN ROUND(julianday(closed_at) - julianday(requested_at), 2) END AS days_to_close
FROM requests_clean;

-- Check: valid_for_sla should be 179,842 and on_time / valid_for_sla = 68.1%
SELECT COUNT(*) AS total_rows,
       SUM(valid_for_sla) AS valid_for_sla,
       SUM(on_time) AS on_time,
       ROUND(100.0 * SUM(on_time) / SUM(valid_for_sla), 1) AS on_time_pct
FROM requests_bi;
