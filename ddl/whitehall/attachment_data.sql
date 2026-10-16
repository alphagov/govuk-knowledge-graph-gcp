CREATE TABLE `govuk-knowledge-graph.whitehall.attachment_data`
(
  id INT64 OPTIONS(description="The ID of the attachment data"),
  carrierwave_file STRING OPTIONS(description="The name of the attached file"),
  content_type STRING OPTIONS(description="The MIME type of the attached file"),
  file_size INT64 OPTIONS(description="The size of the attached file"),
  number_of_pages INT64 OPTIONS(description="The number of pages in the attached file"),
  created_at TIMESTAMP OPTIONS(description="The created timestamp of the attachment data"),
  updated_at TIMESTAMP OPTIONS(description="The updated timestamp of the attachment data"),
  replaced_by_id INT64 OPTIONS(description="The ID of the replacement AttachmentData")
)
PARTITION BY TIMESTAMP_TRUNC(updated_at, MONTH)
OPTIONS(
  friendly_name="Attachment Data",
  description="Attachment Data table from the GOV.UK Whitehall MySQL database",
  labels=[("goog-terraform-provisioned", "true")]
);