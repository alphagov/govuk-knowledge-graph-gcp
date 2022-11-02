resource "google_compute_address" "neo4j" {
  address      = "34.105.179.197"
  address_type = "EXTERNAL"
  description  = "Static external IP address for Neo4j instances"
  name         = "neo4j"
  network_tier = "PREMIUM"
  project      = "govuk-knowledge-graph"
  region       = "europe-west2"
}
# terraform import google_compute_address.neo4j projects/govuk-knowledge-graph/regions/europe-west2/addresses/neo4j
