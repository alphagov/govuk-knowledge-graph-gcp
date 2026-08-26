CREATE TABLE `govuk-knowledge-graph.publishing_api.unpublishings`
(
  id INT64,
  edition_id INT64,
  type STRING,
  explanation STRING,
  alternative_path STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  unpublished_at TIMESTAMP,
  redirects JSON
)
PARTITION BY RANGE_BUCKET(edition_id, GENERATE_ARRAY(0, 100000000, 25000))
OPTIONS(
  friendly_name="Unpublishings",
  description="Unpublishings table from the GOV.UK Publishing API PostgreSQL database"
);