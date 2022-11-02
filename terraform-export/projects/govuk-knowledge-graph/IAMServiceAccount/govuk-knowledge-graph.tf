resource "google_service_account" "govuk_knowledge_graph" {
  account_id   = "govuk-knowledge-graph"
  display_name = "App Engine default service account"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.govuk_knowledge_graph projects/govuk-knowledge-graph/serviceAccounts/govuk-knowledge-graph@govuk-knowledge-graph.iam.gserviceaccount.com
