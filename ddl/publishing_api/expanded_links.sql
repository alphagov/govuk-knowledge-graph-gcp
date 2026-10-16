CREATE TABLE `govuk-knowledge-graph.publishing_api.expanded_links`
(
  id INT64,
  content_id STRING,
  locale STRING,
  with_drafts BOOL,
  payload_version INT64,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  expanded_links JSON
)
OPTIONS(
  friendly_name="Expanded links",
  description="Expanded links table from the GOV.UK Publishing API PostgreSQL database"
);