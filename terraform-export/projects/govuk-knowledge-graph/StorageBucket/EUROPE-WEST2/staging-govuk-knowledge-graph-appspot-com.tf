resource "google_storage_bucket" "staging_govuk_knowledge_graph_appspot_com" {
  force_destroy = false

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age        = 15
      with_state = "ANY"
    }
  }

  location                 = "EUROPE-WEST2"
  name                     = "staging.govuk-knowledge-graph.appspot.com"
  project                  = "govuk-knowledge-graph"
  public_access_prevention = "inherited"
  storage_class            = "STANDARD"
}
# terraform import google_storage_bucket.staging_govuk_knowledge_graph_appspot_com staging.govuk-knowledge-graph.appspot.com
