BEGIN TRANSACTION;

-- 1. Safely empty target (retains all schema, partition, and clustering properties)

TRUNCATE TABLE `{project_id}.{dw_dataset}.editions`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.editions`
(
  id,
  panopticon_id,
  version_number,
  sibling_in_progress,
  title,
  in_beta,
  publish_at,
  overview,
  slug,
  rejected_count,
  asignee,
  reviewer,
  creator,
  publisher,
  archiver,
  major_change,
  change_note,
  state,
  review_requested_at,
  auth_bypass_id,
  owning_org_content_ids,
  mongo_id,
  created_at,
  updated_at,
  editionable_type,
  editionable_id,
  assigned_to_id
)
SELECT
  id,
  panopticon_id,
  COALESCE(version_number, 0) AS version_number,
  sibling_in_progress,
  title,
  COALESCE(in_beta, FALSE) AS in_beta,
  SAFE_CAST(publish_at AS TIMESTAMP) AS publish_at,
  overview,
  slug,
  COALESCE(rejected_count, 0) AS rejected_count,
  assignee AS asignee,
  reviewer,
  creator,
  publisher,
  archiver,
  COALESCE(major_change, FALSE) AS major_change,
  change_note,
  COALESCE(state, '') AS state,
  SAFE_CAST(review_requested_at AS TIMESTAMP) AS review_requested_at,
  COALESCE(auth_bypass_id, '') AS auth_bypass_id,
  owning_org_content_ids,
  mongo_id,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
  COALESCE(editionable_type, '') AS editionable_type,
  COALESCE(editionable_id, 0) AS editionable_id,
  assigned_to_id
FROM `{project_id}.{raw_dataset}.editions`;


COMMIT TRANSACTION;