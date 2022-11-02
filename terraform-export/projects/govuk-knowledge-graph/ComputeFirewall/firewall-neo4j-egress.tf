resource "google_compute_firewall" "firewall_neo4j_egress" {
  allow {
    ports    = ["7473", "7687"]
    protocol = "tcp"
  }

  destination_ranges      = ["213.86.153.211", "213.86.153.212", "213.86.153.213", "213.86.153.214", "213.86.153.231", "213.86.153.235", "213.86.153.236", "213.86.153.237", "51.149.8.0/25", "51.149.8.128/29"]
  direction               = "EGRESS"
  name                    = "firewall-neo4j-egress"
  network                 = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/networks/default"
  priority                = 1000
  project                 = "govuk-knowledge-graph"
  target_service_accounts = ["gce-neo4j@govuk-knowledge-graph.iam.gserviceaccount.com"]
}
# terraform import google_compute_firewall.firewall_neo4j_egress projects/govuk-knowledge-graph/global/firewalls/firewall-neo4j-egress
