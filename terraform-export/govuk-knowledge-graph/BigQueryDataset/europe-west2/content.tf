resource "google_bigquery_dataset" "content" {
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  access {
    role          = "READER"
    user_by_email = "bigquery-page-transitions@govuk-knowledge-graph.iam.gserviceaccount.com"
  }

  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }

  access {
    role          = "WRITER"
    user_by_email = "gce-mongodb@govuk-knowledge-graph.iam.gserviceaccount.com"
  }

  dataset_id                 = "content"
  delete_contents_on_destroy = false
  description                = "GOV.UK content data"
  friendly_name              = "content"
  location                   = "europe-west2"
  project                    = "govuk-knowledge-graph"
}
# terraform import google_bigquery_dataset.content projects/govuk-knowledge-graph/datasets/content
