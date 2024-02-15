# Scheduled queries that don't belong in terraform configurations of particular
# datasets.

resource "google_service_account" "bigquery_scheduled_queries" {
  account_id   = "bigquery-scheduled"
  display_name = "Bigquery scheduled queries"
  description  = "Service account for scheduled BigQuery queries"
}

resource "google_bigquery_data_transfer_config" "publishing_api_editions_current" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Publishing API editions current"
  location       = var.region
  schedule       = "every day 00:00"
  params = {
    query = file("bigquery/publishing-api-editions-current.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries.email
}
