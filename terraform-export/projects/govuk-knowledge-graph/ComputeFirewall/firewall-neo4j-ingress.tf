resource "google_compute_firewall" "firewall_neo4j_ingress" {
  allow {
    ports    = ["7473", "7474", "7687"]
    protocol = "tcp"
  }

  direction               = "INGRESS"
  name                    = "firewall-neo4j-ingress"
  network                 = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/networks/default"
  priority                = 1000
  project                 = "govuk-knowledge-graph"
  source_ranges           = ["213.86.153.211", "213.86.153.212", "213.86.153.213", "213.86.153.214", "213.86.153.231", "213.86.153.235", "213.86.153.236", "213.86.153.237", "51.149.8.0/25", "51.149.8.128/29"]
  target_service_accounts = ["gce-neo4j@govuk-knowledge-graph.iam.gserviceaccount.com"]
}
# terraform import google_compute_firewall.firewall_neo4j_ingress projects/govuk-knowledge-graph/global/firewalls/firewall-neo4j-ingress
