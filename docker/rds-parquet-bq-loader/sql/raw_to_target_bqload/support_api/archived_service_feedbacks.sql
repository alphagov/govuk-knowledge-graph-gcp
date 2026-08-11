
BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.archived_service_feedbacks`;

-- 2: Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.archived_service_feedbacks` (
  id,
  type,
  slug,
  service_satisfaction_rating,
  created_at,
  updated_at
)
SELECT
  id,
  type,
  slug,
  service_satisfaction_rating,
  -- Safely cast STRING date/times to TIMESTAMPS (returns NULL on bad string formats rather than failing)
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at
FROM `{project_id}.{raw_dataset}.archived_service_feedbacks`
-- Safety filters to prevent inserting NULLs into columns that require NOT NULL constraints
WHERE id IS NOT NULL;

COMMIT TRANSACTION;
