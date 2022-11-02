resource "google_service_account" "gce_postgres" {
  account_id   = "gce-postgres"
  description  = "Service account for the postgres instance on GCE"
  display_name = "Service Account for postgres Instance"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.gce_postgres projects/govuk-knowledge-graph/serviceAccounts/gce-postgres@govuk-knowledge-graph.iam.gserviceaccount.com
