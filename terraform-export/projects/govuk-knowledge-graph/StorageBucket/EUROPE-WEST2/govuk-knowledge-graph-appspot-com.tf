resource "google_storage_bucket" "govuk_knowledge_graph_appspot_com" {
  force_destroy            = false
  location                 = "EUROPE-WEST2"
  name                     = "govuk-knowledge-graph.appspot.com"
  project                  = "govuk-knowledge-graph"
  public_access_prevention = "inherited"
  storage_class            = "STANDARD"
}
# terraform import google_storage_bucket.govuk_knowledge_graph_appspot_com govuk-knowledge-graph.appspot.com
