# https://neo4j.com/docs/operations-manual/current/cloud-deployments/neo4j-gcp/automation-gcp/

resource "google_service_account" "gce_neo4j" {
  account_id   = "gce-neo4j"
  display_name = "Service Account for Neo4j Instance"
  description  = "Service account for the Neo4j instance on GCE"
}

# terraform import google_compute_network.default default
resource "google_compute_network" "default" {
  name        = "default"
  description = "Default network for the project"
}

resource "google_compute_address" "neo4j" {
  name         = "neo4j"
  network_tier = "STANDARD"
}

resource "google_compute_firewall" "neo4j-ingress" {
  name    = "firewall-neo4j-ingress"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["7473", "7687"]
  }

  # https://sites.google.com/a/digital.cabinet-office.gov.uk/gds/working-at-gds/gds-internal-it/gds-internal-it-network-public-ip-addresses
  source_ranges = [
    "213.86.153.212",
    "213.86.153.213",
    "213.86.153.214",
    "213.86.153.235",
    "213.86.153.236",
    "213.86.153.237",
    "213.86.153.211",
    "213.86.153.231",
    "51.149.8.0/25",
    "51.149.8.128/29"
  ]

  target_service_accounts = [google_service_account.gce_neo4j.email]
}

resource "google_compute_firewall" "neo4j-egress" {
  name      = "firewall-neo4j-egress"
  network   = google_compute_network.default.name
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["7473", "7687"]
  }

  # https://sites.google.com/a/digital.cabinet-office.gov.uk/gds/working-at-gds/gds-internal-it/gds-internal-it-network-public-ip-addresses
  destination_ranges = [
    "213.86.153.212",
    "213.86.153.213",
    "213.86.153.214",
    "213.86.153.235",
    "213.86.153.236",
    "213.86.153.237",
    "213.86.153.211",
    "213.86.153.231",
    "51.149.8.0/25",
    "51.149.8.128/29"
  ]

  source_service_accounts = [google_service_account.gce_neo4j.email]
}

resource "google_compute_resource_policy" "neo4j" {
  name        = "neo4j"
  description = "Start and stop the Neo4j instance"
  instance_schedule_policy {
    vm_start_schedule {
      schedule = "0 8 * * 1-5"
    }
    vm_stop_schedule {
      schedule = "0 18 * * *"
    }
    time_zone = "Europe/London"
  }
}

# https://github.com/terraform-google-modules/terraform-google-container-vm
module "gce-advanced-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = "europe-west2-docker.pkg.dev/govuk-knowledge-graph/docker/neo4j-browser:latest"
    tty : true
    stdin : true
  }
}

resource "google_compute_instance" "neo4j" {
  project                   = var.project_id
  name                      = "neo4j"
  machine_type              = "n1-standard-1"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = module.gce-advanced-container.source_image
      size  = 10
    }
  }

  metadata = {
    gce-container-declaration = module.gce-advanced-container.metadata_value
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
      nat_ip       = google_compute_address.neo4j.address
    }
  }

  service_account {
    email  = google_service_account.gce_neo4j.email
    scopes = ["cloud-platform"]
  }

  resource_policies = [google_compute_resource_policy.neo4j.self_link]
}

resource "google_compute_instance_iam_member" "service_agent" {
  instance_name = google_compute_instance.neo4j.name
  role          = "roles/compute.instanceAdmin"
  member        = "serviceAccount:service-${google_project.project.number}@compute-system.iam.gserviceaccount.com"
  # 19513753240@cloudservices.gserviceaccount.com
  # email   = "service-${var.project_id}@compute-system.iam.gserviceaccount.com"
}
