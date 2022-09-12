# A workflow to create an instance from a template, triggered by PubSub

resource "google_service_account" "workflow_mongodb" {
  account_id   = "workflow-mongodb"
  display_name = "Service account for the mongodb workflow"
}

resource "google_service_account" "eventarc" {
  account_id   = "eventarc"
  display_name = "Service account for EventArc to trigger workflows"
}

resource "google_workflows_workflow" "mongodb" {
  name            = "mongodb"
  region          = var.region
  description     = "Run a MongoDB instance from its template"
  service_account = google_service_account.workflow_mongodb.id
  source_contents = <<-EOF
  # This workflow does the following:
  # - Creates an instance from the MongoDB template
  # - [TBC] Creates an instance from the Neo4j template
  # In terraform you need to escape the $$ or it will cause errors.

  - start_mongodb:
      call: googleapis.compute.v1.instances.insert
      args:
          project: ${var.project_id}
          zone: ${var.zone}
          sourceInstanceTemplate: https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/instanceTemplates/mongodb
          body:
              name: mongodb
EOF
}

resource "google_eventarc_trigger" "govuk_integration_database_backups" {
  name            = "mongodb"
  location        = var.region
  service_account = google_service_account.eventarc.email
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }
  destination {
    workflow = google_workflows_workflow.mongodb.id
  }
  transport {
    pubsub {
      topic = google_pubsub_topic.govuk_integration_database_backups.id
    }
  }
}
