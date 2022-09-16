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

main:
  params: [event]
  steps:
  - log_event:
      call: sys.log
      args:
          text: $${event}
          severity: INFO
  - decode_pubsub_message:
      assign:
      - base64: $${base64.decode(event.data.data)}
      - message_text: $${text.decode(base64)}
  - log_message_text:
      call: sys.log
      args:
          text: $${message_text}
          severity: INFO
  - parse_pubsub_message:
      assign:
      - message_json: $${json.decode(message_text)}
  - log_message_json:
      call: sys.log
      args:
          json: $${message_json}
          severity: INFO
  - extract_metadata:
      assign:
      - object_bucket: $${message_json.bucket}
      - object_name: $${message_json.name}
  - maybe_start_mongodb:
      switch:
        - condition: $${text.match_regex(object_name, "^mongo-api/\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}-content_store_production\\.gz$")}
          steps:
          - log_starting_instance:
              call: sys.log
              args:
                  text: "Starting mongodb instance"
                  severity: INFO
          - start_mongodb:
              call: googleapis.compute.v1.instances.insert
              args:
                  project: ${var.project_id}
                  zone: ${var.zone}
                  sourceInstanceTemplate: https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/instanceTemplates/mongodb
                  body:
                      name: mongodb
                      metadata:
                        items:
                        - key: object_bucket
                          value: $${object_bucket}
                        - key: object_name
                          value: $${object_name}
                        - key: gce-container-declaration
                          value: ${jsonencode(module.mongodb-container.metadata_value)}
              next: end
        - condition: true
          steps:
          - log_not_starting_instance:
              call: sys.log
              args:
                  text: "Not starting mongodb instance"
                  severity: INFO
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

resource "google_service_account" "workflow_neo4j" {
  account_id   = "workflow-neo4j"
  display_name = "Service account for the neo4j workflow"
}

# A workflow to turn Neo4j on
resource "google_workflows_workflow" "neo4j_on" {
  name            = "neo4j-on"
  region          = var.region
  description     = "Run a neo4j instance from its template"
  service_account = google_service_account.workflow_neo4j.id
  source_contents = <<-EOF
  # This workflow creates an instance from the neo4j template
  # In terraform you need to escape the $$ or it will cause errors.

main:
  steps:
  - log_starting_instance:
      call: sys.log
      args:
          text: "Starting neo4j instance"
          severity: INFO
  - start_neo4j:
      call: googleapis.compute.v1.instances.insert
      args:
          project: ${var.project_id}
          zone: ${var.zone}
          sourceInstanceTemplate: https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/instanceTemplates/neo4j
          body:
              name: neo4j
EOF
}

# A workflow to turn Neo4j off
resource "google_workflows_workflow" "neo4j_off" {
  name            = "neo4j-off"
  region          = var.region
  description     = "Delete the neo4j instance"
  service_account = google_service_account.workflow_neo4j.id
  source_contents = <<-EOF
  # This workflow deletes an instance named 'neo4j'
  # In terraform you need to escape the $$ or it will cause errors.

main:
  steps:
  - log_deleting_instance:
      call: sys.log
      args:
          text: "Deleting neo4j instance"
          severity: INFO
  - delete_neo4j:
      call: googleapis.compute.v1.instances.delete
      args:
          instance: neo4j
          project: ${var.project_id}
          zone: ${var.zone}
EOF
}


# A service account for Cloud Scheduler to run neo4j on/off workflows
resource "google_service_account" "scheduler_neo4j" {
  account_id   = "scheduler-neo4j"
  display_name = "Service Account for scheduling the Neo4j workflow"
  description  = "Service Account for scheduling the Neo4j workflow"
}

# A schedule to turn Neo4j on
resource "google_cloud_scheduler_job" "neo4j_on" {
  name        = "neo4j-on"
  description = "Switch neo4j on"
  schedule    = "0 7 * * 1-5"
  time_zone   = "Europe/London"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.neo4j_on.id}/executions"
    oauth_token {
      service_account_email = google_service_account.scheduler_neo4j.email
    }
  }
}

# A schedule to turn Neo4j off
resource "google_cloud_scheduler_job" "neo4j_off" {
  name        = "neo4j-off"
  description = "Switch neo4j off"
  schedule    = "0 19 * * *"
  time_zone   = "Europe/London"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.neo4j_off.id}/executions"
    oauth_token {
      service_account_email = google_service_account.scheduler_neo4j.email
    }
  }
}
