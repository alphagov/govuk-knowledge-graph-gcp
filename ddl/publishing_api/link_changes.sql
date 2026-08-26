CREATE TABLE `govuk-knowledge-graph.publishing_api.link_changes`
(
  id INT64,
  source_content_id STRING,
  target_content_id STRING,
  link_type STRING,
  change INT64,
  action_id INT64,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
OPTIONS(
  friendly_name="Link changes",
  description="Link changes table from the GOV.UK Publishing API PostgreSQL database"
);