CREATE TABLE `govuk-knowledge-graph.publishing_api.link_sets`
(
  id INT64,
  content_id STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  stale_lock_version INT64
)
OPTIONS(
  friendly_name="Link sets",
  description="Link sets table from the GOV.UK Publishing API PostgreSQL database"
);