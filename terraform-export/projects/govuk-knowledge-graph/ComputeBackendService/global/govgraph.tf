resource "google_compute_backend_service" "govgraph" {
  connection_draining_timeout_sec = 300
  health_checks                   = ["https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/httpHealthChecks/govgraph"]
  load_balancing_scheme           = "EXTERNAL"
  name                            = "govgraph"
  port_name                       = "http"
  project                         = "govuk-knowledge-graph"
  protocol                        = "HTTP"
  session_affinity                = "NONE"
  timeout_sec                     = 10
}
# terraform import google_compute_backend_service.govgraph projects/govuk-knowledge-graph/global/backendServices/govgraph
