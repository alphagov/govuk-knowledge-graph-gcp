# A dataset of tables for the govsearch app

resource "google_service_account" "bigquery_scheduled_queries_search" {
  account_id   = "bigquery-scheduled-search"
  display_name = "Bigquery scheduled queries for search"
  description  = "Service account for scheduled BigQuery queries for the 'search' dataset"
}

resource "google_bigquery_dataset" "search" {
  dataset_id            = "search"
  friendly_name         = "search"
  description           = "GOV.UK content data"
  location              = "europe-west2"
  max_time_travel_hours = "48"
}

data "google_iam_policy" "bigquery_dataset_search" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      google_service_account.bigquery_scheduled_queries_search.member,
    ]
  }
  binding {
    role = "roles/bigquery.dataOwner"
    members = [
      "projectOwners",
    ]
  }
  binding {
    role = "roles/bigquery.dataViewer"
    members = concat(
      [
        "projectReaders",
        google_service_account.govgraphsearch.member,
        google_service_account.bigquery_scheduled_queries_search.member,
      ],
      var.bigquery_publishing_api_data_viewer_members,
    )
  }
}

resource "google_bigquery_dataset_iam_policy" "search" {
  dataset_id  = google_bigquery_dataset.search.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_search.policy_data
}

resource "google_bigquery_table" "search_page" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "page"
  friendly_name = "Page table for the govsearch app"
  description   = "Page table for the govsearch app"
  schema        = file("schemas/search/page.json")
}

resource "google_bigquery_table" "search_taxon" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "taxon"
  friendly_name = "Taxon"
  description   = "Taxon table for the govsearch app"
  schema        = file("schemas/search/taxon.json")
}

# Because these queries are scheduled, without any way to manage their
# dependencies on source tables, they musn't use each other as a source.
resource "google_bigquery_data_transfer_config" "search_page" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Page"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/page.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_taxon" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Taxon"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/taxon.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}
