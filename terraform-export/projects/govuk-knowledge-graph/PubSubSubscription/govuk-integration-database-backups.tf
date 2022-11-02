resource "google_pubsub_subscription" "govuk_integration_database_backups" {
  ack_deadline_seconds       = 10
  message_retention_duration = "604800s"
  name                       = "govuk-integration-database-backups"
  project                    = "govuk-knowledge-graph"
  retain_acked_messages      = true
  topic                      = "projects/govuk-knowledge-graph/topics/govuk-integration-database-backups"
}
# terraform import google_pubsub_subscription.govuk_integration_database_backups projects/govuk-knowledge-graph/subscriptions/govuk-integration-database-backups
