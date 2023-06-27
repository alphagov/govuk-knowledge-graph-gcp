# A dataset of tables of GOV.UK content and related raw statistics

resource "google_bigquery_dataset" "content" {
  dataset_id            = "content"
  friendly_name         = "content"
  description           = "GOV.UK content data"
  location              = "europe-west2"
  max_time_travel_hours = "48"
}

data "google_iam_policy" "bigquery_dataset_content_dataEditor" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.gce_postgres.email}",
      "serviceAccount:${google_service_account.gce_neo4j.email}",
      "serviceAccount:${google_service_account.workflow_bank_holidays.email}",
      "serviceAccount:${google_service_account.bigquery_page_transitions.email}",
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
    members = [
      "projectReaders",
      "serviceAccount:ner-bulk-inference@cpto-content-metadata.iam.gserviceaccount.com",
      "serviceAccount:wif-ner-new-content-inference@cpto-content-metadata.iam.gserviceaccount.com",
      "serviceAccount:wif-govgraph-bigquery-access@govuk-llm-question-answering.iam.gserviceaccount.com",
      "serviceAccount:${google_service_account.bigquery_scheduled_queries_search.email}",
      "serviceAccount:${google_service_account.govgraphsearch.email}",
      "group:govsearch-data-viewers@digital.cabinet-office.gov.uk"
    ]
  }
}

resource "google_bigquery_dataset_iam_policy" "content" {
  dataset_id  = google_bigquery_dataset.content.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_content_dataEditor.policy_data
}

locals {
  table_names = fileset(path.module, "schemas/*.json")
  table_files = [for table in local.table_names: file(table)]
  table_defs = [for table in local.table_files: jsondecode(table)]
}

resource "google_bigquery_table" "content_tables" {

  for_each      = {for table_def in local.table_defs: table_def.table_id => table_def}

  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = each.value.table_id
  friendly_name = each.value.friendly_name
  description   = each.value.description
  schema        = jsonencode(each.value.schema)
}