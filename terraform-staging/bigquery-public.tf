# A dataset of tables derived from elsewhere that may be accessible from outside
# of GOV.UK.

resource "google_bigquery_dataset" "public" {
  dataset_id            = "public"
  friendly_name         = "Public"
  description           = "Data that must not be accessible from outside of GOV.UK"
  location              = "europe-west2"
  max_time_travel_hours = "48" # The minimum is 48
}

data "google_iam_policy" "bigquery_dataset_public" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      google_service_account.bigquery_scheduled_queries.member,
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
      ],
      var.bigquery_public_data_viewer_members,
    )
  }
}

resource "google_bigquery_dataset_iam_policy" "public" {
  dataset_id  = google_bigquery_dataset.public.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_public.policy_data
}

resource "google_bigquery_table" "public_publishing_api_editions_current" {
  dataset_id    = google_bigquery_dataset.public.dataset_id
  table_id      = "publishing_api_editions_current"
  friendly_name = "Publishing API editions (current)"
  description   = "The most-recent edition of each document of each content item"
  schema        = file("schemas/public/publishing-api-editions-current.json")
}

resource "google_bigquery_table" "public_publishing_api_editions_new_current" {
  dataset_id    = google_bigquery_dataset.public.dataset_id
  table_id      = "publishing_api_editions_new_current"
  friendly_name = "Publishing API editions (new and current)"
  description   = "Publishing API editions from the latest batch update, that are also current"
  schema        = file("schemas/public/publishing-api-editions-new-current.json")
}
