CREATE TABLE `govuk-knowledge-graph.whitehall.documents`
(
  id INT64 OPTIONS(description="The ID of the document"),
  content_id STRING OPTIONS(description="The content ID of the document"),
  created_at TIMESTAMP OPTIONS(description="The created timestamp of the document"),
  updated_at TIMESTAMP OPTIONS(description="The updated timestamp of the document"),
  document_type STRING OPTIONS(description="The type of the document"),
  latest_edition_id INT64 OPTIONS(description="The ID of the latest edition of the document"),
  live_edition_id INT64 OPTIONS(description="The ID of the live edition of the document")
)
PARTITION BY TIMESTAMP_TRUNC(updated_at, MONTH)
CLUSTER BY document_type
OPTIONS(
  friendly_name="Documents",
  description="Documents table from the GOV.UK Whitehall MySQL database",
  labels=[("goog-terraform-provisioned", "true")]
);