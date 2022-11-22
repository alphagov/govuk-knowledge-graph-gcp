resource "google_cloud_run_service" "govgraphsearch" {
  name     = "terraformed-govgraphsearch"
  location = "europe-west2"

  template {
    spec {
      containers {
        image = "europe-west2-docker.pkg.dev/govuk-knowledge-graph/cloud-run-source-deploy/govuk-knowledge-graph-search@sha256:eb081ab035fb77184f9c4e1dc10c9140076f3dcf3f0e2b88c51033a02a401dad"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}