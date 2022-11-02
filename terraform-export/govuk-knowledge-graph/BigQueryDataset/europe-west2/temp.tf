resource "google_bigquery_dataset" "temp" {
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "OWNER"
    user_by_email = "duncan.garmonsway@digital.cabinet-office.gov.uk"
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }

  dataset_id                  = "temp"
  default_table_expiration_ms = 604800000
  delete_contents_on_destroy  = false
  location                    = "europe-west2"
  project                     = "govuk-knowledge-graph"
}
# terraform import google_bigquery_dataset.temp projects/govuk-knowledge-graph/datasets/temp
