
BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.documents`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.documents` (
  id,
  content_id,
  created_at,
  updated_at,
  document_type,
  latest_edition_id,
  live_edition_id
)
SELECT
  id,
  content_id,
  created_at,
  updated_at,
  document_type,
  latest_edition_id,
  live_edition_id
FROM `{project_id}.{raw_dataset}.documents`;

COMMIT TRANSACTION;