CREATE TABLE `govuk-knowledge-graph.support_api.archived_service_feedbacks`
(
  id INT64 NOT NULL,
  type STRING,
  slug STRING,
  service_satisfaction_rating INT64,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
OPTIONS(
  friendly_name="Archived service feedback",
  description="Service feedback (rating out of 5, and what could be improved)"
);