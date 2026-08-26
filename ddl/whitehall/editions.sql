CREATE TABLE `govuk-knowledge-graph.whitehall.editions`
(
  id INT64 OPTIONS(description="The ID of the edition"),
  created_at TIMESTAMP OPTIONS(description="The created timestamp of the edition"),
  updated_at TIMESTAMP OPTIONS(description="The updated timestamp of the edition"),
  document_id INT64 OPTIONS(description="The ID of the document that the edition belongs to"),
  state STRING OPTIONS(description="The publication status of the edition"),
  type STRING OPTIONS(description="The document type of the edition"),
  major_change_published_at TIMESTAMP OPTIONS(description="The time at which the last edition with a major change on the parent document was published"),
  first_published_at TIMESTAMP OPTIONS(description="The time at which the parent document was first published"),
  force_published BOOL OPTIONS(description="A flag to indicate whether the edition has been published without 21"),
  public_timestamp TIMESTAMP OPTIONS(description="The publicly visible time at which the edition appears to have been published (this may be different to the actual publication time)"),
  scheduled_publication TIMESTAMP OPTIONS(description="The time at which the edition has been scheduled for publication"),
  access_limited BOOL OPTIONS(description="A flag to indicate whether the edition is restricted from the view of other organisations than the lead organisations (draft editions only)"),
  opening_at TIMESTAMP OPTIONS(description="The time at which some edition types are open for public feedback"),
  closing_at TIMESTAMP OPTIONS(description="The time at which some edition types are closed for public feedback"),
  political BOOL OPTIONS(description="A flag to indicate whether the edition is associated with a government"),
  primary_locale STRING OPTIONS(description="The language code of the primary locale"),
  auth_bypass_id STRING OPTIONS(description="A token used to compose a shareable preview url"),
  government_id INT64 OPTIONS(description="The ID of the government that the edition is associated with"),
  slug STRING OPTIONS(description="The slug of the edition")
)
PARTITION BY TIMESTAMP_TRUNC(updated_at, MONTH)
CLUSTER BY state, type
OPTIONS(
  friendly_name="Editions",
  description="Editions table from the GOV.UK Whitehall MySQL database",
  labels=[("goog-terraform-provisioned", "true")]
);