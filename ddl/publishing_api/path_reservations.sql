CREATE TABLE `govuk-knowledge-graph.publishing_api.path_reservations`
(
  id INT64,
  base_path STRING,
  publishing_app STRING,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
OPTIONS(
  friendly_name="Path reservations",
  description="Path reservations table from the GOV.UK Publishing API PostgreSQL database"
);