
BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.path_reservations`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.path_reservations`
(
  id,
  base_path,
  publishing_app,
  created_at,
  updated_at
)
SELECT
  id,
  base_path,
  publishing_app,
  SAFE_CAST(created_at AS TIMESTAMP),
  SAFE_CAST(updated_at AS TIMESTAMP)
FROM
  `{project_id}.{raw_dataset}.path_reservations`;

COMMIT TRANSACTION;