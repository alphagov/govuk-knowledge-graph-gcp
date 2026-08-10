
BEGIN TRANSACTION;

-- 1: Safely empty target (retaining partition, cluster, and option properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.anonymous_contacts`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.anonymous_contacts` (
  id,
  type,
  what_doing,
  what_wrong,
  details,
  source,
  page_owner,
  user_agent,
  referrer,
  javascript_enabled,
  created_at,
  updated_at,
  personal_information_status,
  slug,
  service_satisfaction_rating,
  user_specified_url,
  is_actionable,
  reason_why_not_actionable,
  path,
  content_item_id,
  marked_as_spam,
  reviewed
)
SELECT
  id,
  type,
  what_doing,
  what_wrong,
  details,
  source,
  page_owner,
  user_agent,
  referrer,
  javascript_enabled,
  CAST(created_at AS TIMESTAMP) AS created_at,
  CAST(updated_at AS TIMESTAMP) AS updated_at,
  personal_information_status,
  slug,
  service_satisfaction_rating,
  user_specified_url,
  is_actionable,
  reason_why_not_actionable,
  path,
  content_item_id,
  marked_as_spam,
  reviewed
FROM `{project_id}.{raw_dataset}.anonymous_contacts`
-- Safety filters to prevent inserting NULLs into columns that require NOT NULL constraints
WHERE id IS NOT NULL
  AND type IS NOT NULL
  AND path IS NOT NULL
  AND created_at IS NOT NULL
  AND updated_at IS NOT NULL;

COMMIT TRANSACTION;