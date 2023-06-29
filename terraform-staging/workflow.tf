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
  description     = "Run a databases instances from their templates"
  service_account = google_service_account.workflow_govuk_integration_database_backups.id
  source_contents = templatefile(
    "workflows/govuk-integration-database-backups.yaml",
    {
      project_id              = var.project_id,
      zone                    = var.zone,
      postgres_startup_script = jsonencode(var.postgres-startup-script),
      mongodb_metadata_value  = jsonencode(module.mongodb-container.metadata_value),
      postgres_metadata_value = jsonencode(module.postgres-container.metadata_value)
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

# A workflow to fetch bank holiday data
resource "google_service_account" "workflow_bank_holidays" {
  account_id   = "workflow-bank-holidays"
  display_name = "Service account for the bank-holidays workflow"
}

resource "google_bigquery_routine" "load_bank_holiday_occurrences" {
  dataset_id = google_bigquery_dataset.content.dataset_id
  routine_id     = "load_bank_holiday_occurrences"
  routine_type = "PROCEDURE"
  language = "SQL"
  definition_body = file("queries/load_bank_holiday_occurrences.sql")
}

resource "google_bigquery_routine" "load_bank_holiday_raw" {
  dataset_id = google_bigquery_dataset.content.dataset_id
  routine_id     = "load_bank_holiday_raw"
  routine_type = "PROCEDURE"
  language = "SQL"
  definition_body = templatefile(
    "queries/load_bank_holiday_raw.sql", 
    { 
      project_id = var.project_id 
    }
  )
}

resource "google_bigquery_routine" "load_bank_holiday_titles" {
  dataset_id = google_bigquery_dataset.content.dataset_id
  routine_id     = "load_bank_holiday_titles"
  routine_type = "PROCEDURE"
  language = "SQL"
  definition_body = file("queries/load_bank_holiday_titles.sql")
}

resource "google_bigquery_routine" "load_bank_holiday_url" {
  dataset_id = google_bigquery_dataset.content.dataset_id
  routine_id     = "load_bank_holiday_url"
  routine_type = "PROCEDURE"
  language = "SQL"
  definition_body = file("queries/load_bank_holiday_url.sql")
}

resource "google_workflows_workflow" "bank_holidays" {
  name            = "bank-holidays"
  region          = var.region
  description     = "Fetch bank holiday data from https://www.gov.uk/bank-holidays.json"
  service_account = google_service_account.workflow_bank_holidays.id
  source_contents = templatefile(
    "workflows/bank-holidays.yaml",
    {
      processed_bucket     = "${var.project_id}-data-processed",
      project_id           = var.project_id,
      load_raw_query       = "CALL content.load_bank_holiday_raw()"
      load_occurence_query = "CALL content.load_bank_holiday_occurrences()"
      load_url_query       = "CALL content.load_bank_holiday_url()"
      load_titles_query    = "CALL content.load_bank_holiday_titles()"
    }
  )
}

# A service account for Cloud Scheduler to run the bank-holidays workflow
resource "google_service_account" "scheduler_bank_holidays" {
  account_id   = "scheduler-bank-holidays"
  display_name = "Service Account for scheduling the bank holidays workflow"
  description  = "Service Account for scheduling the bank holidays workflow"
}

# A schedule to fetch bank holiday data
resource "google_cloud_scheduler_job" "bank_holidays" {
  name        = "bank-holidays"
  description = "Fetch bank holiday data"
  schedule    = "0 2 * * *"
  time_zone   = "Europe/London"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.bank_holidays.id}/executions"
    oauth_token {
      service_account_email = google_service_account.scheduler_bank_holidays.email
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
