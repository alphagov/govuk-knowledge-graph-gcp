BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.link_changes`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.link_changes` (
  id,
  source_content_id,
  target_content_id,
  link_type,
  change,
  action_id,
  created_at,
  updated_at
)
SELECT
  id,
  source_content_id,
  target_content_id,
  link_type,
  change,
  action_id,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at
FROM `{project_id}.{raw_dataset}.link_changes`;

COMMIT TRANSACTION;