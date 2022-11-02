resource "google_bigquery_table" "body_lines" {
  dataset_id      = "temp"
  expiration_time = 1665007134531
  project         = "govuk-knowledge-graph"
  schema          = "[{\"mode\":\"NULLABLE\",\"name\":\"string_field_0\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"string_field_1\",\"type\":\"STRING\"}]"
  table_id        = "body_lines"
}
# terraform import google_bigquery_table.body_lines projects/govuk-knowledge-graph/datasets/temp/tables/body_lines
