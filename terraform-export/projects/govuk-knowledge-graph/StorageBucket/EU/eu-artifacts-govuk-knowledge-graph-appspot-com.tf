resource "google_storage_bucket" "eu_artifacts_govuk_knowledge_graph_appspot_com" {
  force_destroy            = false
  location                 = "EU"
  name                     = "eu.artifacts.govuk-knowledge-graph.appspot.com"
  project                  = "govuk-knowledge-graph"
  public_access_prevention = "inherited"
  storage_class            = "STANDARD"
}
# terraform import google_storage_bucket.eu_artifacts_govuk_knowledge_graph_appspot_com eu.artifacts.govuk-knowledge-graph.appspot.com
