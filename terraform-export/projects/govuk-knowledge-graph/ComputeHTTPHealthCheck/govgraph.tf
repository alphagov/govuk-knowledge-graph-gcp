resource "google_compute_http_health_check" "govgraph" {
  check_interval_sec  = 1
  healthy_threshold   = 2
  name                = "govgraph"
  port                = 80
  project             = "govuk-knowledge-graph"
  request_path        = "/"
  timeout_sec         = 1
  unhealthy_threshold = 2
}
# terraform import google_compute_http_health_check.govgraph projects/govuk-knowledge-graph/global/httpHealthChecks/govgraph
