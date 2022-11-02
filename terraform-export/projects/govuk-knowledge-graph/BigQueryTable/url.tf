resource "google_bigquery_table" "url" {
  dataset_id    = "content"
  description   = "Unique URLs of static content on the www.gov.uk domain, not including parts of 'guide' and 'travel_advice' pages"
  friendly_name = "GOV.UK unique URLs"
  project       = "govuk-knowledge-graph"
  schema        = "[{\"description\":\"URL of a piece of content on the www.gov.uk domain\",\"mode\":\"REQUIRED\",\"name\":\"url\",\"type\":\"STRING\"}]"
  table_id      = "url"
}
# terraform import google_bigquery_table.url projects/govuk-knowledge-graph/datasets/content/tables/url
