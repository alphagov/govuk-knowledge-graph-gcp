resource "google_service_account" "eventarc" {
  account_id   = "eventarc"
  display_name = "Service account for EventArc to trigger workflows"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.eventarc projects/govuk-knowledge-graph/serviceAccounts/eventarc@govuk-knowledge-graph.iam.gserviceaccount.com
