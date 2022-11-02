resource "google_compute_target_https_proxy" "govgraph" {
  name             = "govgraph"
  project          = "govuk-knowledge-graph"
  quic_override    = "NONE"
  ssl_certificates = ["https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/sslCertificates/govgraph"]
  url_map          = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/urlMaps/govgraph"
}
# terraform import google_compute_target_https_proxy.govgraph projects/govuk-knowledge-graph/global/targetHttpsProxies/govgraph
