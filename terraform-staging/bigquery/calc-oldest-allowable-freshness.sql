CREATE OR REPLACE FUNCTION `${project_id}.functions.calc_oldest_allowable_freshness`(timestamp TIMESTAMP)
RETURNS TIMESTAMP
AS (
  CASE
    -- BigQuery Days: 1=Sunday, 2=Monday, 3=Tuesday... 7=Saturday
    WHEN EXTRACT(DAYOFWEEK FROM timestamp) = 7 THEN TIMESTAMP_ADD(timestamp, INTERVAL - 49 HOUR) -- Saturday (48h + 1h tolerance)
    WHEN EXTRACT(DAYOFWEEK FROM timestamp) = 1 THEN TIMESTAMP_ADD(timestamp, INTERVAL - 73 HOUR) -- Sunday (72h + 1h tolerance)
    WHEN EXTRACT(DAYOFWEEK FROM timestamp) = 2 THEN TIMESTAMP_ADD(timestamp, INTERVAL - 73 HOUR) -- Monday (72h + 1h tolerance)
    ELSE TIMESTAMP_ADD(timestamp, INTERVAL - 25 HOUR) -- (24h + 1h tolerance)
  END
);
