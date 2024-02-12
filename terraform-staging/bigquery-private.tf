# A dataset of tables derived from elsewhere that must not be accessible from
# outside of GOV.UK.

resource "google_bigquery_dataset" "private" {
  dataset_id            = "private"
  friendly_name         = "Private"
  description           = "Data that must not be accessible from outside of GOV.UK"
  location              = "europe-west2"
  max_time_travel_hours = "48" # The minimum is 48
}

data "google_iam_policy" "bigquery_dataset_private" {
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
      var.bigquery_private_data_viewer_members,
    )
  }
}

resource "google_bigquery_dataset_iam_policy" "private" {
  dataset_id  = google_bigquery_dataset.private.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_private.policy_data
}
