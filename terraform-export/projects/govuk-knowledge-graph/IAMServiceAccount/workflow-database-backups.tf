resource "google_service_account" "workflow_database_backups" {
  account_id   = "workflow-database-backups"
  display_name = "Service account for the govuk-integration-database-backups workflow"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.workflow_database_backups projects/govuk-knowledge-graph/serviceAccounts/workflow-database-backups@govuk-knowledge-graph.iam.gserviceaccount.com
