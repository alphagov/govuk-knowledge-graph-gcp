resource "google_project" "govuk_knowledge_graph" {
  auto_create_network = true
  billing_account     = "015C7A-FAF970-B0D375"
  folder_id           = "278098142879"

  labels = {
    programme = "cpto"
    team      = "data-products"
  }

  name       = "govuk-knowledge-graph"
  project_id = "govuk-knowledge-graph"
}
# terraform import google_project.govuk_knowledge_graph projects/govuk-knowledge-graph
