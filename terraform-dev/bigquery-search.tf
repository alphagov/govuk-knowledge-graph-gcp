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
      var.bigquery_publishing_data_viewer_members,
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

resource "google_bigquery_table" "search_person" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "person"
  friendly_name = "Person"
  description   = "Person table for the govsearch app"
  schema        = file("schemas/search/person.json")
}

resource "google_bigquery_table" "search_organisation" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "organisation"
  friendly_name = "Organisation"
  description   = "Organisation table for the govsearch app"
  schema        = file("schemas/search/organisation.json")
}

resource "google_bigquery_table" "search_role" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "role"
  friendly_name = "Role"
  description   = "Role table for the govsearch app"
  schema        = file("schemas/search/role.json")
}

resource "google_bigquery_table" "search_taxon" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "taxon"
  friendly_name = "Taxon"
  description   = "Taxon table for the govsearch app"
  schema        = file("schemas/search/taxon.json")
}

resource "google_bigquery_table" "search_entity_types" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "entityTypes"
  friendly_name = "Entity types"
  description   = "Entity types table for the govsearch app, from https://github.com/alphagov/govuk-content-metadata"
  schema        = file("schemas/search/entity-types.json")
}

resource "google_bigquery_table" "search_transaction" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "transaction"
  friendly_name = "Transaction"
  description   = "Transaction table for the govsearch app"
  schema        = file("schemas/search/transaction.json")
}

resource "google_bigquery_table" "search_bank_holiday" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "bank_holiday"
  friendly_name = "Bank holiday"
  description   = "Bank holiday table for the govsearch app"
  schema        = file("schemas/search/bank-holiday.json")
}

resource "google_bigquery_table" "search_thing" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "thing"
  friendly_name = "Thing"
  description   = "Thing table for the govsearch app"
  schema        = file("schemas/search/thing.json")
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

resource "google_bigquery_data_transfer_config" "search_person" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Person"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/person.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_role" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Role"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/role.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_organisation" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Organisation"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/organisation.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_transation" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Transaction"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/transaction.sql")
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

resource "google_bigquery_data_transfer_config" "search_entity_type" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Entity type"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/entity-type.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_bank_holiday" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Bank holiday"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/bank-holiday.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_thing" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Thing"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/thing.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}
