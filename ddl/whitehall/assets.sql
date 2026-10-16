CREATE TABLE `govuk-knowledge-graph.whitehall.assets`
(
  id INT64 OPTIONS(description="The ID of the asset"),
  asset_manager_id STRING OPTIONS(description="The Asset Manager unique identifier for the asset"),
  variant STRING OPTIONS(description="Some assets have different versions of the same file (such as image sizes). Default is 'original'."),
  created_at TIMESTAMP OPTIONS(description="The created timestamp of the asset"),
  updated_at TIMESTAMP OPTIONS(description="The updated timestamp of the asset"),
  assetable_type STRING OPTIONS(description="The type of the model the asset is associated with (for example 'AttachmentData')"),
  assetable_id INT64 OPTIONS(description="The ID of the model the asset is associated with (for example the 'AttachmentData' ID)"),
  filename STRING OPTIONS(description="The name of the attached file")
)
PARTITION BY TIMESTAMP_TRUNC(updated_at, MONTH)
CLUSTER BY assetable_type
OPTIONS(
  friendly_name="Assets",
  description="Assets table from the GOV.UK Whitehall MySQL database",
  labels=[("goog-terraform-provisioned", "true")]
);