resource "google_pubsub_subscription" "eventarc_europe_west2_govuk_integration_database_backups_sub_934" {
  ack_deadline_seconds = 10

  labels = {
    goog-eventarc = ""
  }

  message_retention_duration = "86400s"
  name                       = "eventarc-europe-west2-govuk-integration-database-backups-sub-934"
  project                    = "govuk-knowledge-graph"

  push_config {
    oidc_token {
      audience              = "https://workflowexecutions.googleapis.com/v1/projects/govuk-knowledge-graph/locations/europe-west2/workflows/govuk-integration-database-backups:triggerPubsubExecution"
      service_account_email = "eventarc@govuk-knowledge-graph.iam.gserviceaccount.com"
    }

    push_endpoint = "https://workflowexecutions.googleapis.com/v1/projects/govuk-knowledge-graph/locations/europe-west2/workflows/govuk-integration-database-backups:triggerPubsubExecution?__GCP_CloudEventsMode=CUSTOM_PUBSUB_projects%2Fgovuk-knowledge-graph%2Ftopics%2Fgovuk-integration-database-backups"
  }

  retry_policy {
    maximum_backoff = "600s"
    minimum_backoff = "10s"
  }

  topic = "projects/govuk-knowledge-graph/topics/govuk-integration-database-backups"
}
# terraform import google_pubsub_subscription.eventarc_europe_west2_govuk_integration_database_backups_sub_934 projects/govuk-knowledge-graph/subscriptions/eventarc-europe-west2-govuk-integration-database-backups-sub-934
