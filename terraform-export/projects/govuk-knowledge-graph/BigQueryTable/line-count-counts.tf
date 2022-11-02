resource "google_bigquery_table" "line_count_counts" {
  dataset_id      = "temp"
  expiration_time = 1665007493057
  project         = "govuk-knowledge-graph"
  schema          = "[{\"name\":\"n\",\"type\":\"INTEGER\"},{\"name\":\"n_count\",\"type\":\"INTEGER\"}]"
  table_id        = "line_count_counts"
}
# terraform import google_bigquery_table.line_count_counts projects/govuk-knowledge-graph/datasets/temp/tables/line_count_counts
