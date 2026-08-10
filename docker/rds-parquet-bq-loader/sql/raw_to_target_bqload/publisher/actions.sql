BEGIN TRANSACTION;

-- 1. Safely empty target (retains all schema, partition, and clustering properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.actions`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.actions`
SELECT
  id,
  approver_id,
  SAFE_CAST(approved AS TIMESTAMP) AS approved_timestamp,
  comment AS comment_character,
  COALESCE(comment_sanitized, FALSE) AS comment_sanitized,
  request_type,
  COALESCE(
    SAFE.PARSE_JSON(request_details),
    JSON '{{}}'
  ) AS request_details,
  email_addresses AS email_address,
  customised_message,
  mongo_id,
  SAFE_CAST(created_at AS TIMESTAMP) AS create_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
  edition_id,
  requester_id,
  recipient_id,
  requester_name
FROM `{project_id}.{raw_dataset}.actions`;

COMMIT TRANSACTION;