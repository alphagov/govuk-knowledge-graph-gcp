resource "google_service_account" "workflow_neo4j" {
  account_id   = "workflow-neo4j"
  display_name = "Service account for the neo4j workflow"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.workflow_neo4j projects/govuk-knowledge-graph/serviceAccounts/workflow-neo4j@govuk-knowledge-graph.iam.gserviceaccount.com
