resource "google_compute_url_map" "govgraph" {
  default_service = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/backendServices/govgraph"
  description     = "URL map for govgraph.dev"

  host_rule {
    hosts        = ["govgraph.dev."]
    path_matcher = "allpaths"
  }

  name = "govgraph"

  path_matcher {
    default_service = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/backendServices/govgraph"
    name            = "allpaths"

    path_rule {
      paths   = ["/*"]
      service = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/backendServices/govgraph"
    }
  }

  project = "govuk-knowledge-graph"
}
# terraform import google_compute_url_map.govgraph projects/govuk-knowledge-graph/global/urlMaps/govgraph
