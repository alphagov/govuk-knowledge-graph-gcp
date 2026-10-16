CREATE TABLE `govuk-knowledge-graph.asset_manager.assets`
(
  _id STRING OPTIONS(description="The Asset Manager MongoDB ID for the asset"),
  created_at TIMESTAMP OPTIONS(description="The time at which the asset was created"),
  updated_at TIMESTAMP OPTIONS(description="The time at which the asset was last updated"),
  replacement_id STRING OPTIONS(description="The ID of the replacement asset (this asset will redirect to it)"),
  state STRING OPTIONS(description="The state of the asset, relating to upload and virus scanning status"),
  filename_history ARRAY<STRING> OPTIONS(description="An array comprising the asset's history of filenames"),
  uuid STRING OPTIONS(description="The asset UUID"),
  draft BOOL OPTIONS(description="A flag indicating whether the asset is available on the draft or live stack"),
  redirect_url STRING OPTIONS(description="The URL the asset should redirect to"),
  last_modified TIMESTAMP OPTIONS(description="The last time the asset was modified"),
  size INT64 OPTIONS(description="The size of the asset"),
  content_type STRING OPTIONS(description="The MIME type of the asset"),
  access_limited ARRAY<STRING> OPTIONS(description="An array comprising access limited user content IDs (deprecated)"),
  access_limited_organisation_ids ARRAY<STRING> OPTIONS(description="An array comprising access limited organisation content IDs"),
  parent_document_url STRING OPTIONS(description="The URL of the parent document, either a draft or live url"),
  deleted_at TIMESTAMP OPTIONS(description="The time at which the asset was deleted from Asset Manager"),
  file STRING OPTIONS(description="The name of the asset file"),
  _type STRING OPTIONS(description="Legacy field, either 'WhitehallAsset' or 'Asset', used to capture whether an asset came from Whitehall; Whitehall assets had a legacy_url_path"),
  legacy_url_path STRING OPTIONS(description="The legacy path at which a WhitehallAsset can be found")
)
PARTITION BY TIMESTAMP_TRUNC(updated_at, MONTH)
CLUSTER BY content_type
OPTIONS(
  friendly_name="Assets",
  description="Assets table from the GOV.UK Asset Manager mongo database",
  labels=[("goog-terraform-provisioned", "true")]
);