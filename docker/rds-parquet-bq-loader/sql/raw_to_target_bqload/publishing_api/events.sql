BEGIN TRANSACTION;

-- 1. Safely empty target (retains all schema, partition, and clustering properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.events`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.events` (
  id,
  action,
  user_uid,
  created_at,
  updated_at,
  request_id,
  content_id,
  payload
)
SELECT
  id,
  action,
  user_uid,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
  request_id,
  content_id,
  SAFE.PARSE_JSON(payload) AS payload -- Safely parses JSON strings into BigQuery's native JSON columnar format
FROM `{project_id}.{raw_dataset}.events`;

COMMIT TRANSACTION;