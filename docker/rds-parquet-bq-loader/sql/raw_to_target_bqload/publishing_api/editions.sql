BEGIN TRANSACTION;

--1. Safely empty target (retains all schema, partition, and clustering properties)
TRUNCATE TABLE `{project_id}.{dw_dataset}.editions`;

-- 2. Exttract data from raw, transform, and populate target
INSERT INTO `{project_id}.{dw_dataset}.editions` (
  id,
  title,
  public_updated_at,
  publishing_app,
  rendering_app,
  update_type,
  phase,
  analytics_identifier,
  created_at,
  updated_at,
  document_type,
  schema_name,
  first_published_at,
  last_edited_at,
  state,
  user_facing_version,
  base_path,
  content_store,
  document_id,
  description,
  publishing_request_id,
  major_published_at,
  published_at,
  publishing_api_first_published_at,
  publishing_api_last_edited_at,
  auth_bypass_ids,
  details,
  routes,
  redirects,
  last_edited_by_editor_id
)
SELECT
  id,
  title,
  SAFE_CAST(public_updated_at AS TIMESTAMP) AS public_updated_at,
  publishing_app,
  rendering_app,
  update_type,
  phase,
  analytics_identifier,
  SAFE_CAST(created_at AS TIMESTAMP) AS created_at,
  SAFE_CAST(updated_at AS TIMESTAMP) AS updated_at,
  document_type,
  schema_name,
  SAFE_CAST(first_published_at AS TIMESTAMP) AS first_published_at,
  SAFE_CAST(last_edited_at AS TIMESTAMP) AS last_edited_at,
  state,
  user_facing_version,
  base_path,
  content_store,
  document_id,
  description,
  publishing_request_id,
  SAFE_CAST(major_published_at AS TIMESTAMP) AS major_published_at,
  SAFE_CAST(published_at AS TIMESTAMP) AS published_at,
  SAFE_CAST(publishing_api_first_published_at AS TIMESTAMP) AS publishing_api_first_published_at,
  SAFE_CAST(publishing_api_last_edited_at AS TIMESTAMP) AS publishing_api_last_edited_at,
  auth_bypass_ids,
  SAFE.PARSE_JSON(details) AS details,       
  SAFE.PARSE_JSON(routes) AS routes,         
  SAFE.PARSE_JSON(redirects) AS redirects,   
  last_edited_by_editor_id
FROM `{project_id}.{raw_dataset}.editions`;

COMMIT TRANSACTION;