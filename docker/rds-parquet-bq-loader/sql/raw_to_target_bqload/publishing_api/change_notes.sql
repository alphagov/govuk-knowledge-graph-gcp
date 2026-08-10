BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.change_notes`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.change_notes` (
  id,
  note,
  public_timestamp,
  edition_id,
  created_at,
  updated_at,
  document_id,
  user_facing_version
)
SELECT
  id,
  note,
  SAFE_CAST(public_timestamp AS TIMESTAMP) AS public_timestamp,
  edition_id,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
  document_id,
  user_facing_version
FROM `{project_id}.{raw_dataset}.change_notes`;

COMMIT TRANSACTION;