resource "google_compute_disk" "neo4j" {
  image                     = "https://www.googleapis.com/compute/beta/projects/cos-cloud/global/images/cos-stable-101-17162-40-5"
  name                      = "neo4j"
  physical_block_size_bytes = 4096
  project                   = "govuk-knowledge-graph"
  size                      = 40
  type                      = "pd-standard"
  zone                      = "europe-west2-b"
}
# terraform import google_compute_disk.neo4j projects/govuk-knowledge-graph/zones/europe-west2-b/disks/neo4j
