
BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.assets`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.assets` (
  id,
  asset_manager_id,
  variant,
  created_at,
  updated_at,
  assetable_type,
  assetable_id,
  filename
)
SELECT
  id,
  asset_manager_id,
  variant,
  created_at,
  updated_at,
  assetable_type,
  assetable_id,
  filename
FROM `{project_id}.{raw_dataset}.assets`;

COMMIT TRANSACTION;
