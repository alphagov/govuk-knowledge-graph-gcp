resource "google_dns_managed_zone" "govgraph" {
  description   = "DNS zone for .dev domains"
  dns_name      = "govgraph.dev."
  force_destroy = false
  name          = "govgraph"
  project       = "govuk-knowledge-graph"
  visibility    = "public"
}
# terraform import google_dns_managed_zone.govgraph projects/govuk-knowledge-graph/managedZones/govgraph
