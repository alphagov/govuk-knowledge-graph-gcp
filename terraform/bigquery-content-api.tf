# A dataset of tables of GOV.UK content and related raw statistics

resource "google_bigquery_dataset" "content_api" {
  dataset_id            = "content_api"
  friendly_name         = "Content API"
  description           = "Tables from the GOV.UK Content API database"
  location              = "europe-west2"
  max_time_travel_hours = "48" # The minimum is 48
}

data "google_iam_policy" "bigquery_dataset_content_api" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      google_service_account.gce_content_api.member,
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
    members = concat([
      "projectReaders",
      ],
      var.bigquery_content_api_data_viewer_members,
    )
  }
}

resource "google_bigquery_dataset_iam_policy" "content_api" {
  dataset_id  = google_bigquery_dataset.content_api.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_content_api.policy_data
}

resource "google_bigquery_table" "content_api_content_items" {
  dataset_id    = google_bigquery_dataset.content_api.dataset_id
  table_id      = "content_items"
  friendly_name = "Content items"
  description   = "Content items table from the GOV.UK Content Store PostgreSQL database"
  schema        = file("schemas/content-api/content-items.json")
}
