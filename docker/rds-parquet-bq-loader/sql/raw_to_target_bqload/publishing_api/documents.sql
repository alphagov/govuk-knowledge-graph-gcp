BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.documents`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.documents`
(
  id,
  content_id,
  locale,
  stale_lock_version,
  created_at,
  updated_at,
  owning_document_id
)
SELECT
  id,
  content_id,
  locale,
  stale_lock_version,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
  owning_document_id
FROM
  `{project_id}.{raw_dataset}.documents`;

COMMIT TRANSACTION;