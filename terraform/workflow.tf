# A workflow to create an instance from a template

resource "google_service_account" "workflow" {
  account_id   = "workflow-mongodb"
  display_name = "Service account for the workflow"
}

resource "google_workflows_workflow" "workflow" {
  name            = "workflow"
  region          = var.region
  description     = "Run MongoDB and Neo4j instances from their templates"
  service_account = google_service_account.workflow.id
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