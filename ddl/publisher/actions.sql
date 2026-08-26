CREATE TABLE `govuk-knowledge-graph.publisher.actions`
(
  id INT64 NOT NULL OPTIONS(description="ID of action"),
  approver_id INT64 OPTIONS(description="ID of user who approved edit if this is an approval action"),
  approved_timestamp TIMESTAMP OPTIONS(description="Time of approval if this is an approval action"),
  comment_character STRING,
  comment_sanitized BOOL NOT NULL,
  request_type STRING NOT NULL,
  request_details JSON NOT NULL,
  email_address STRING,
  customised_message STRING,
  mongo_id STRING,
  create_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  edition_id STRING,
  requester_id INT64,
  recipient_id INT64,
  requester_name STRING
)
OPTIONS(
  friendly_name="Actions",
  description="Actions table derived from the GOV.UK Publisher app Mongo database. Many actions occur per edition, leading to publication.",
  labels=[("goog-terraform-provisioned", "true")]
);