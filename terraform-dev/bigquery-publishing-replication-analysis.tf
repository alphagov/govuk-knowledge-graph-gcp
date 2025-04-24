resource "google_bigquery_dataset" "publishing_replication_analysis" {
  dataset_id            = "publishing_replication_analysis"
  friendly_name         = "Publishing Replication Analysis"
  description           = "Dataset for analysis of GOV.UK state replication effectiveness"
  location              = "europe-west2"
  max_time_travel_hours = "48"
}

data "google_iam_policy" "bigquery_dataset_publishing_replication_analysis" {
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
        google_service_account.bigquery_scheduled_queries_search.member,
      ],
      var.bigquery_publishing_replication_analysis_data_viewer_members,
    )
  }
}

resource "google_bigquery_dataset_iam_policy" "publishing_replication_analysis" {
  dataset_id  = google_bigquery_dataset.publishing_replication_analysis.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_publishing_replication_analysis.policy_data
}

resource "google_bigquery_table" "whitehall_attachment_assets_join_asset_manager_assets" {
  dataset_id          = google_bigquery_dataset.publishing_replication_analysis.dataset_id
  table_id            = "whitehall_attachment_assets_join_asset_manager_assets"

  view {
    query          = file("bigquery/whitehall-assets-join-asset-manager-assets.sql")
    use_legacy_sql = false
  }
}
