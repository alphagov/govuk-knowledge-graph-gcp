# A dataset of tables from the Whitehall mysql database

resource "google_bigquery_dataset" "whitehall" {
  dataset_id            = "whitehall"
  friendly_name         = "Whitehall"
  description           = "Data from the GOV.UK Whitehall database"
  location              = "europe-west2"
  max_time_travel_hours = "48"
}

data "google_iam_policy" "bigquery_dataset_whitehall" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      google_service_account.bigquery_scheduled_queries.member,
      google_service_account.gce_whitehall.member,
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
        google_service_account.bigquery_scheduled_queries_search.member,
      ],
      var.bigquery_whitehall_data_viewer_members,
    )
  }
}

resource "google_bigquery_dataset_iam_policy" "whitehall" {
  dataset_id  = google_bigquery_dataset.whitehall.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_whitehall.policy_data
}

resource "google_bigquery_table" "whitehall_editions" {
  dataset_id    = google_bigquery_dataset.whitehall.dataset_id
  table_id      = "editions"
  friendly_name = "Editions"
  description   = "Editions table from the GOV.UK Whitehall MySQL database"
  schema        = file("schemas/whitehall/editions.json")
  clustering    = ["state", "type"]
  time_partitioning {
    type  = "MONTH"
    field = "updated_at"
  }
}


