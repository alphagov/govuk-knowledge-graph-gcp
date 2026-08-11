
BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.links`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.links` (
  id,
  target_content_id,
  link_type,
  created_at,
  updated_at,
  position,
  edition_id,
  link_set_content_id
)
SELECT
  id,
  target_content_id,
  link_type,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
  position,
  edition_id,
  link_set_content_id
FROM 
  `{project_id}.{raw_dataset}.links`;

COMMIT TRANSACTION;