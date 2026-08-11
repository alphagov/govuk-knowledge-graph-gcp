BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.link_sets`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.link_sets` (
  id,
  content_id,
  created_at,
  updated_at,
  stale_lock_version
)
SELECT
  id,
  content_id,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
  stale_lock_version
FROM `{project_id}.{raw_dataset}.link_sets`;

COMMIT TRANSACTION;