resource "google_service_account" "19513753240_compute" {
  account_id   = "19513753240-compute"
  display_name = "Compute Engine default service account"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.19513753240_compute projects/govuk-knowledge-graph/serviceAccounts/19513753240-compute@govuk-knowledge-graph.iam.gserviceaccount.com
