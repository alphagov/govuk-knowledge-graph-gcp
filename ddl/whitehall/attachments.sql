CREATE TABLE `govuk-knowledge-graph.whitehall.attachments`
(
  id INT64 OPTIONS(description="The ID of the attachment"),
  created_at TIMESTAMP OPTIONS(description="The created timestamp of the attachment"),
  updated_at TIMESTAMP OPTIONS(description="The updated timestamp of the attachment"),
  title STRING OPTIONS(description="The title of the attachment"),
  attachment_data_id INT64 OPTIONS(description="The ID of the attachment data the attachment is associated with"),
  attachable_id INT64 OPTIONS(description="The ID of the attachable the attachment is associated with. The attachable can be an edition, or a non-editionable model.`"),
  attachable_type STRING OPTIONS(description="The type of the attachable the attachment is associated with. The attachable can be an edition, or a non-editionable model.`"),
  type STRING OPTIONS(description="The type of the attachment"),
  slug STRING OPTIONS(description="The slug of the attachment (only for HTML Attachments)"),
  locale STRING OPTIONS(description="The locale of the attachment (only for HTML Attachments)"),
  content_id STRING OPTIONS(description="The content ID of the attachment (only for HTML Attachments)"),
  deleted BOOL OPTIONS(description="A flag to indicate whether the attachment is deleted")
)
PARTITION BY TIMESTAMP_TRUNC(updated_at, MONTH)
CLUSTER BY type
OPTIONS(
  friendly_name="Attachments",
  description="Attachments table from the GOV.UK Whitehall MySQL database",
  labels=[("goog-terraform-provisioned", "true")]
);