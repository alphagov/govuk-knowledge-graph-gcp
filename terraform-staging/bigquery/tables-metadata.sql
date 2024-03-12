-- For alerting and debugging.
--
-- For each table in the project, its modified date and row count, sorted
-- ascending.
WITH tables AS (
  SELECT * FROM content.__TABLES__
  UNION ALL
  SELECT * FROM graph.__TABLES__
  UNION ALL
  SELECT * FROM private.__TABLES__
  UNION ALL
  SELECT * FROM public.__TABLES__
  UNION ALL
  SELECT * FROM publishing_api.__TABLES__
  UNION ALL
  SELECT * FROM search.__TABLES__
)
SELECT
  dataset_id,
  table_id,
  TIMESTAMP_MILLIS(last_modified_time) AS last_modified,
  row_count
FROM tables
ORDER BY
  last_modified,
  row_count
;
