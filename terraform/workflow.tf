# A workflow to create an instance from a template, triggered by PubSub

resource "google_service_account" "workflow_govuk_integration_database_backups" {
  account_id   = "workflow-database-backups"
  display_name = "Service account for the govuk-integration-database-backups workflow"
}

resource "google_service_account" "eventarc" {
  account_id   = "eventarc"
  display_name = "Service account for EventArc to trigger workflows"
}

resource "google_workflows_workflow" "govuk_integration_database_backups" {
  name            = "govuk-integration-database-backups"
  region          = var.region
  description     = "Run database instances from their templates"
  service_account = google_service_account.workflow_govuk_integration_database_backups.id
  source_contents = templatefile(
    "workflows/govuk-integration-database-backups.yaml",
    {
      project_id                    = var.project_id
      zone                          = var.zone
      postgres_startup_script       = jsonencode(var.postgres-startup-script)
      content_api_metadata_value    = jsonencode(module.content-api-container.metadata_value)
      content_metadata_value        = jsonencode(module.content-container.metadata_value)
      mongodb_metadata_value        = jsonencode(module.mongodb-container.metadata_value)
      publishing_api_metadata_value = jsonencode(module.publishing-api-container.metadata_value)
      publisher_metadata_value      = jsonencode(module.publisher-container.metadata_value)
    }
  )
}

resource "google_eventarc_trigger" "govuk_integration_database_backups" {
  name            = "govuk-integration-database-backups"
  location        = var.region
  service_account = google_service_account.eventarc.email
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    workflow = google_workflows_workflow.govuk_integration_database_backups.id
  }
  transport {
    pubsub {
      topic = google_pubsub_topic.govuk_integration_database_backups.id
    }
  }
}

# A workflow to fetch page views from GA4 and export them to a file in a bucket
resource "google_workflows_workflow" "page_views" {
  name            = "page-views"
  region          = var.region
  description     = "Fetch page view counts from GA4 into BigQuery and export to a bucket"
  service_account = google_service_account.bigquery_page_transitions.id
  source_contents = file("workflows/workflow-page-views.yaml")
}

# A service account for Cloud Scheduler to run the page_views workflow
resource "google_service_account" "scheduler_page_views" {
  account_id   = "scheduler-page-views"
  display_name = "Service Account for scheduling the page-views workflow"
  description  = "Service Account for scheduling the page-views workflow"
}

# A schedule to fetch page view statistics
resource "google_cloud_scheduler_job" "page_views" {
  name        = "page-views"
  description = "Fetch page-view statistics"
  schedule    = "0 3 * * *"
  time_zone   = "Europe/London"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.page_views.id}/executions"
    oauth_token {
      service_account_email = google_service_account.scheduler_page_views.email
    }
  }
}

# A service account for the redis-cli workflow
resource "google_service_account" "workflow_redis_cli" {
  account_id   = "workflow-redis-cli"
  display_name = "Service account for the redis-cli workflow"
}

# A workflow to start a virtual machine to access the Memorystore Redis instance
resource "google_workflows_workflow" "redis_cli" {
  name            = "redis-cli"
  region          = var.region
  description     = "Create a virtual machine for accessing the Memorystore Redis instance"
  service_account = google_service_account.workflow_redis_cli.id

  # Enable / Disable
  count = var.enable_redis_session_store_instance ? 1 : 0

  source_contents = templatefile(
    "workflows/redis-cli.yaml",
    {
      project_id     = var.project_id,
      zone           = var.zone,
      network_name   = google_redis_instance.session_store[0].authorized_network,
      subnetwork_id  = google_compute_subnetwork.cloudrun.id,
      metadata_value = jsonencode(module.redis-cli-container[0].metadata_value)
    }
  )
}
