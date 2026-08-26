CREATE TABLE `govuk-knowledge-graph.publishing_api.documents`
(
  id INT64,
  content_id STRING,
  locale STRING,
  stale_lock_version INT64,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  owning_document_id INT64
)
PARTITION BY RANGE_BUCKET(id, GENERATE_ARRAY(0, 15000000, 3750))
OPTIONS(
  friendly_name="Documents",
  description="Documents table from the GOV.UK Publishing API PostgreSQL database"
);