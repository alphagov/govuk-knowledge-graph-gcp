resource "google_service_account" "gce_neo4j" {
  account_id   = "gce-neo4j"
  description  = "Service account for the Neo4j instance on GCE"
  display_name = "Service Account for Neo4j Instance"
  project      = "govuk-knowledge-graph"
}
# terraform import google_service_account.gce_neo4j projects/govuk-knowledge-graph/serviceAccounts/gce-neo4j@govuk-knowledge-graph.iam.gserviceaccount.com
