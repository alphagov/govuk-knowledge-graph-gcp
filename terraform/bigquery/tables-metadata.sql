-- For alerting and debugging.
--
-- For each table in the project, its modified date and row count, sorted
-- ascending.
WITH all_objects AS (
  SELECT * FROM content.__TABLES__
  UNION ALL
  SELECT * FROM private.__TABLES__
  UNION ALL
  SELECT * FROM public.__TABLES__
  UNION ALL
  SELECT * FROM publishing_api.__TABLES__
  UNION ALL
  SELECT * FROM support_api.__TABLES__
  UNION ALL
  SELECT * FROM search.__TABLES__
  UNION ALL
  SELECT * FROM asset_manager.__TABLES__
  UNION ALL
  SELECT * FROM publisher.__TABLES__
)
-- The objects have to be filtered on type = 1. This will only include native tables.
-- The column `last_modified_time` can only be relied upon to detect changes in rows of native tables.
-- Other objects such as views and external tables have different semantics which would need a different approach.
, tables AS (
  SELECT *
  FROM all_objects
  WHERE type = 1
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
