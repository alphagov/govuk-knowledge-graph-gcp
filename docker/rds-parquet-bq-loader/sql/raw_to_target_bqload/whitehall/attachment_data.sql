
BEGIN TRANSACTION;

-- 1. Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.attachment_data`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.attachment_data` (
  id,
  carrierwave_file,
  content_type,
  file_size,
  number_of_pages,
  created_at,
  updated_at,
  replaced_by_id
)
SELECT
  id,
  carrierwave_file,
  content_type,
  file_size,
  number_of_pages,
  created_at,
  updated_at,
  replaced_by_id
FROM `{project_id}.{raw_dataset}.attachment_data`;

COMMIT TRANSACTION;
