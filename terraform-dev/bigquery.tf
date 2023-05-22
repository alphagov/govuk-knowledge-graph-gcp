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

data "google_iam_policy" "bigquery_dataset_test" {
  binding {
    role = "roles/bigquery.dataOwner"
    members = [
      "projectOwners",
    ]
  }
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      "serviceAccount:${google_service_account.bigquery_scheduled_queries_search.email}",
    ]
  }
  binding {
    role = "roles/bigquery.dataViewer"
    members = [
      "projectReaders",
      "group:data-engineering@digital.cabinet-office.gov.uk",
      "group:data-analysis@digital.cabinet-office.gov.uk",
      "group:data-products@digital.cabinet-office.gov.uk",
    ]
  }
}

resource "google_bigquery_dataset_iam_policy" "test" {
  dataset_id  = google_bigquery_dataset.test.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_test.policy_data
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

resource "google_bigquery_table" "tables_metadata_check_results" {
  dataset_id    = google_bigquery_dataset.test.dataset_id
  table_id      = "tables-metadata-check-results"
  friendly_name = "Tables metadata check results"
  description   = "Results of the previous run of the check-tables-metatdata scheduled query"
  schema = jsonencode(
    [
      {
        name        = "dataset_id"
        type        = "STRING"
      },
      {
        name        = "table_id"
        type        = "STRING"
      },
      {
        name        = "last_modified"
        type        = "TIMESTAMP"
      },
      {
        name        = "row_count"
        type        = "INTEGER"
      },
      {
        name        = "result"
        type        = "STRING"
      },
    ]
  )
}

resource "google_bigquery_data_transfer_config" "check_tables_metadata" {
  display_name   = "Check tables metadata"
  data_source_id = "scheduled_query" # This is a magic word
  location       = var.region
  schedule       = "every hour"
  params = {
    query = templatefile(
      "bigquery/check-tables-metadata.sql",
      { project_id = var.project_id }
    )
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_monitoring_notification_channel" "data_products" {
  display_name = "Data Products"
  type         = "email"
  labels = {
    email_address = "data-products@digital.cabinet-office.gov.uk"
  }
}

resource "google_monitoring_alert_policy" "tables_metadata" {
  display_name = "Tables metadata"
  combiner     = "OR"
  conditions {
    display_name = "Error condition"
    condition_matched_log {
      filter = "resource.type=\"bigquery_resource\" severity=\"ERROR\" protoPayload.methodName=\"jobservice.jobcompleted\" SEARCH(protoPayload.status.message, \"Old data in table\") OR SEARCH(protoPayload.status.message, \"No data in table\")"
    }
  }

  notification_channels = [ google_monitoring_notification_channel.data_products.name ]
  alert_strategy {
    notification_rate_limit {
      // One day
      period = "86400s"
    }
  }
}

resource "google_bigquery_routine" "page_views" {
  dataset_id      = google_bigquery_dataset.content.dataset_id
  routine_id      = "page_views"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = file("bigquery/page-views.sql")
}
