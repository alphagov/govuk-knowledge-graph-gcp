CREATE TABLE `govuk-knowledge-graph.publishing_api.editions`
(
  id INT64,
  title STRING,
  public_updated_at TIMESTAMP,
  publishing_app STRING,
  rendering_app STRING,
  update_type STRING,
  phase STRING,
  analytics_identifier STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  document_type STRING,
  schema_name STRING,
  first_published_at TIMESTAMP,
  last_edited_at TIMESTAMP,
  state STRING,
  user_facing_version INT64,
  base_path STRING,
  content_store STRING,
  document_id INT64,
  description STRING,
  publishing_request_id STRING,
  major_published_at TIMESTAMP,
  published_at TIMESTAMP,
  publishing_api_first_published_at TIMESTAMP,
  publishing_api_last_edited_at TIMESTAMP,
  auth_bypass_ids STRING,
  details JSON,
  routes JSON,
  redirects JSON,
  last_edited_by_editor_id STRING
)
PARTITION BY TIMESTAMP_TRUNC(updated_at, MONTH)
OPTIONS(
  friendly_name="Editions",
  description="Editions table from the GOV.UK Publishing API PostgreSQL database"
);