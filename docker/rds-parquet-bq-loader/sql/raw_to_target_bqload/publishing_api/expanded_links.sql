BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.expanded_links`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.expanded_links` (
  id,
  content_id,
  locale,
  with_drafts,
  payload_version,
  created_at,
  updated_at,
  expanded_links
)
SELECT
  id,
  content_id,
  locale,
  with_drafts,
  payload_version,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
  SAFE.PARSE_JSON(expanded_links) AS expanded_links -- Parses STRING link map into native BigQuery JSON format
FROM `{project_id}.{raw_dataset}.expanded_links`;

COMMIT TRANSACTION;