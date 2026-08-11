
BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.attachments`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.attachments` (
  id,
  created_at,
  updated_at,
  title,
  attachment_data_id,
  attachable_id,
  attachable_type,
  type,
  slug,
  locale,
  content_id,
  deleted
)
SELECT
  id,
  created_at,
  updated_at,
  title,
  attachment_data_id,
  attachable_id,
  attachable_type,
  type,
  slug,
  locale,
  content_id,
  -- Convert MySQL-style TINYINT/INT (0 or 1) to a proper BigQuery BOOLEAN
  CAST(deleted AS BOOL) AS deleted
FROM `{project_id}.{raw_dataset}.attachments`;

COMMIT TRANSACTION;