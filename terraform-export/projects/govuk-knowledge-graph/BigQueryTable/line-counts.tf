resource "google_bigquery_table" "line_counts" {
  dataset_id      = "temp"
  expiration_time = 1665007491303
  project         = "govuk-knowledge-graph"
  schema          = "[{\"name\":\"string_field_1\",\"type\":\"STRING\"},{\"name\":\"n\",\"type\":\"INTEGER\"}]"
  table_id        = "line_counts"
}
# terraform import google_bigquery_table.line_counts projects/govuk-knowledge-graph/datasets/temp/tables/line_counts
