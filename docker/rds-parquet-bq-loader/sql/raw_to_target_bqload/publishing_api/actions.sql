BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.actions`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.actions` (
  id,
  content_id,
  locale,
  action,
  user_uid,
  edition_id,
  link_set_id,
  event_id,
  created_at,
  updated_at
)
SELECT
  id,
  content_id,
  locale,
  action,
  user_uid,
  edition_id,
  link_set_id,
  event_id,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at
FROM `{project_id}.{raw_dataset}.actions`;

COMMIT TRANSACTION;