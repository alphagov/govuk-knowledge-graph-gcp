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
