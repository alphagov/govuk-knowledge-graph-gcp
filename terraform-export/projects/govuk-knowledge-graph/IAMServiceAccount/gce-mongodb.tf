resource "google_service_account" "gce_mongodb" {
  account_id   = "gce-mongodb"
  description  = "Service account for the MongoDB instance on GCE"
  display_name = "Service Account for MongoDB Instance"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.gce_mongodb projects/govuk-knowledge-graph/serviceAccounts/gce-mongodb@govuk-knowledge-graph.iam.gserviceaccount.com
