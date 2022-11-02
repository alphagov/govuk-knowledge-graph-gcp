resource "google_storage_bucket" "govuk_knowledge_graph_tfstate" {
  force_destroy               = false
  location                    = "EUROPE-WEST2"
  name                        = "govuk-knowledge-graph-tfstate"
  project                     = "govuk-knowledge-graph"
  public_access_prevention    = "inherited"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}
# terraform import google_storage_bucket.govuk_knowledge_graph_tfstate govuk-knowledge-graph-tfstate
