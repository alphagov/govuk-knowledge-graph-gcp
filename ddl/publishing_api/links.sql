CREATE TABLE `govuk-knowledge-graph.publishing_api.links`
(
  id INT64,
  target_content_id STRING,
  link_type STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  position INT64,
  edition_id INT64,
  link_set_content_id STRING
)
OPTIONS(
  friendly_name="Links",
  description="Links table from the GOV.UK Publishing API PostgreSQL database",
  labels=[("goog-terraform-provisioned", "true")]
);