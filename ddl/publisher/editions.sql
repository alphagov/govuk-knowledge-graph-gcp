CREATE TABLE `govuk-knowledge-graph.publisher.editions`
(
  id STRING NOT NULL,
  panopticon_id STRING,
  version_number INT64 NOT NULL,
  sibling_in_progress INT64,
  title STRING,
  in_beta BOOL NOT NULL,
  publish_at TIMESTAMP,
  overview STRING,
  slug STRING,
  rejected_count INT64 NOT NULL,
  asignee STRING,
  reviewer STRING,
  creator STRING,
  publisher STRING,
  archiver STRING,
  major_change BOOL NOT NULL,
  change_note STRING,
  state STRING NOT NULL,
  review_requested_at TIMESTAMP,
  auth_bypass_id STRING NOT NULL,
  owning_org_content_ids STRING,
  mongo_id STRING,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  editionable_type STRING NOT NULL,
  editionable_id INT64 NOT NULL,
  assigned_to_id INT64
)
OPTIONS(
  friendly_name="Editions",
  description="Editions table derived from the GOV.UK Publisher app Mongo database",
  labels=[("goog-terraform-provisioned", "true")]
);