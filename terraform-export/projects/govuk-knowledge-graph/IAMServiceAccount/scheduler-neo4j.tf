resource "google_service_account" "scheduler_neo4j" {
  account_id   = "scheduler-neo4j"
  description  = "Service Account for scheduling the Neo4j workflow"
  display_name = "Service Account for scheduling the Neo4j workflow"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.scheduler_neo4j projects/govuk-knowledge-graph/serviceAccounts/scheduler-neo4j@govuk-knowledge-graph.iam.gserviceaccount.com
