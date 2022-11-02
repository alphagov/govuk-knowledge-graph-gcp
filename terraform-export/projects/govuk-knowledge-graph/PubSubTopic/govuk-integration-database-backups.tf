resource "google_pubsub_topic" "govuk_integration_database_backups" {
  message_retention_duration = "604800s"

  message_storage_policy {
    allowed_persistence_regions = ["europe-west2"]
  }

  name    = "govuk-integration-database-backups"
  project = "govuk-knowledge-graph"
}
# terraform import google_pubsub_topic.govuk_integration_database_backups projects/govuk-knowledge-graph/topics/govuk-integration-database-backups
