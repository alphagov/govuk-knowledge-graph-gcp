resource "google_compute_ssl_certificate" "govgraph" {
  name    = "govgraph"
  project = "govuk-knowledge-graph"
}
# terraform import google_compute_ssl_certificate.govgraph projects/govuk-knowledge-graph/global/sslCertificates/govgraph
