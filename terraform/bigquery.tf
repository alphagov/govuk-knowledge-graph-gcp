resource "google_service_account" "bigquery_page_transitions" {
  account_id   = "bigquery-page-transitions"
  display_name = "Service account for page transitions query"
  description  = "Service account for a scheduled BigQuery query of page-to-page transition counts"
}

resource "google_bigquery_data_transfer_config" "page_to_page_transitions" {
  display_name   = "Page-to-page transitions"
  data_source_id = "scheduled_query" # This is a magic word
  location       = var.region
  schedule       = "every day 03:00"
  params = {
    query = templatefile(
      "bigquery/page-to-page-transitions.sql",
      { project_id = var.project_id }
    )
  }
  service_account_name = google_service_account.bigquery_page_transitions.email
}

resource "google_bigquery_dataset" "test" {
  dataset_id            = "test"
  friendly_name         = "test"
  description           = "Test queries"
  location              = "europe-west2"
  max_time_travel_hours = "48"
}

resource "google_bigquery_table" "tables_metadata" {
  dataset_id    = google_bigquery_dataset.test.dataset_id
  table_id      = "tables-metadata"
  friendly_name = "Tables metadata"
  description   = "Table modified date and row count, sorted ascending"
  view {
    use_legacy_sql = false
    query          = <<EOF
WITH tables AS (
  SELECT * FROM content.__TABLES__
  UNION ALL
  SELECT * FROM graph.__TABLES__
  UNION ALL
  SELECT * FROM publishing.__TABLES__
  UNION ALL
  SELECT * FROM search.__TABLES__
)
SELECT
  dataset_id,
  table_id,
  TIMESTAMP_MILLIS(last_modified_time) AS last_modified,
  row_count
FROM tables
ORDER BY
  last_modified,
  row_count
;
EOF
  }
}

resource "google_bigquery_routine" "page_views" {
  dataset_id = google_bigquery_dataset.content.dataset_id
  routine_id     = "page_views"
  routine_type = "PROCEDURE"
  language = "SQL"
  definition_body = file("bigquery/page-views.sql")
}
