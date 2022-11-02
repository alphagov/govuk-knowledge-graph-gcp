resource "google_storage_bucket" "govuk_knowledge_graph_data_processed" {
  force_destroy = false

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age        = 7
      with_state = "ANY"
    }
  }

  location                    = "EUROPE-WEST2"
  name                        = "govuk-knowledge-graph-data-processed"
  project                     = "govuk-knowledge-graph"
  public_access_prevention    = "inherited"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }
}
# terraform import google_storage_bucket.govuk_knowledge_graph_data_processed govuk-knowledge-graph-data-processed
