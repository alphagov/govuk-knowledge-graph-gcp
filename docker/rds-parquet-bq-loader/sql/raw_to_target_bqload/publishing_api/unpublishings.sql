
BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.unpublishings`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.unpublishings` (
  id,
  edition_id,
  type,
  explanation,
  alternative_path,
  created_at,
  updated_at,
  unpublished_at,
  redirects
)
SELECT
  id,
  edition_id,
  type,
  explanation,
  alternative_path,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
  SAFE_CAST(unpublished_at AS TIMESTAMP) AS unpublished_at,
  SAFE.PARSE_JSON(redirects) AS redirects
FROM
  `{project_id}.{raw_dataset}.unpublishings`;

COMMIT TRANSACTION;