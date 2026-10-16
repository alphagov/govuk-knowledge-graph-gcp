CREATE TABLE `govuk-knowledge-graph.publishing_api.events`
(
  id INT64,
  action STRING,
  user_uid STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  request_id STRING,
  content_id STRING,
  payload JSON
)
OPTIONS(
  friendly_name="Events",
  description="Events table from the GOV.UK Publishing API PostgreSQL database"
);