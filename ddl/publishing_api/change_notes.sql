CREATE TABLE `govuk-knowledge-graph.publishing_api.change_notes`
(
  id INT64,
  note STRING,
  public_timestamp TIMESTAMP,
  edition_id INT64,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  document_id INT64,
  user_facing_version INT64
)
PARTITION BY RANGE_BUCKET(edition_id, GENERATE_ARRAY(0, 100000000, 25000))
OPTIONS(
  friendly_name="Change notes",
  description="Change notes table from the GOV.UK Publishing API PostgreSQL database"
);