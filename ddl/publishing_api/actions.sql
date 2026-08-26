CREATE TABLE `govuk-knowledge-graph.publishing_api.actions`
(
  id INT64,
  content_id STRING,
  locale STRING,
  action STRING,
  user_uid STRING,
  edition_id INT64,
  link_set_id INT64,
  event_id INT64,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
OPTIONS(
  friendly_name="Actions",
  description="Actions table from the GOV.UK Publishing API PostgreSQL database"
);