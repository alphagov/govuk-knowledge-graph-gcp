resource "google_compute_global_forwarding_rule" "govgraph" {
  ip_address            = "34.120.89.80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  name                  = "govgraph"
  port_range            = "443-443"
  project               = "govuk-knowledge-graph"
  target                = "https://www.googleapis.com/compute/beta/projects/govuk-knowledge-graph/global/targetHttpsProxies/govgraph"
}
# terraform import google_compute_global_forwarding_rule.govgraph projects/govuk-knowledge-graph/global/forwardingRules/govgraph
