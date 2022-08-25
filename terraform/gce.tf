# https://neo4j.com/docs/operations-manual/current/cloud-deployments/neo4j-gcp/automation-gcp/

resource "google_service_account" "gce_neo4j" {
  account_id   = "gce-neo4j"
  display_name = "Service Account for Neo4j Instance"
  description  = "Service account for the Neo4j instance on GCE"
}

resource "google_service_account" "gce_mongodb" {
  account_id   = "gce-mongodb"
  display_name = "Service Account for MongoDB Instance"
  description  = "Service account for the MongoDB instance on GCE"
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

resource "google_compute_address" "mongodb" {
  name         = "mongodb"
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

  target_service_accounts = [google_service_account.gce_neo4j.email]
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
module "neo4j-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = "europe-west2-docker.pkg.dev/govuk-knowledge-graph/docker/neo4j:latest"
    tty : true
    stdin : true
  }
}

# https://github.com/terraform-google-modules/terraform-google-container-vm
module "mongodb-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = "europe-west2-docker.pkg.dev/govuk-knowledge-graph/docker/mongodb:latest"
    tty : true
    stdin : true
  }
}

resource "google_compute_instance_template" "neo4j" {
  name         = "neo4j"
  machine_type = "n1-standard-1"

  disk {
    boot         = true
    source_image = module.neo4j-container.source_image
    disk_size_gb = 10
  }

  metadata = {
    gce-container-declaration = module.neo4j-container.metadata_value
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

  # Schedule start and stop
  # resource_policies = [google_compute_resource_policy.neo4j.self_link]
}

resource "google_compute_instance_template" "mongodb" {
  name         = "mongodb"
  machine_type = "e2-highcpu-8"

  disk {
    boot         = true
    source_image = module.mongodb-container.source_image
    disk_size_gb = 20
  }

  metadata = {
    gce-container-declaration = module.mongodb-container.metadata_value
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
      nat_ip       = google_compute_address.mongodb.address
    }
  }

  service_account {
    email  = google_service_account.gce_mongodb.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance_iam_member" "neo4j_instanceAdmin" {
  instance_name = google_compute_instance_template.neo4j.name
  role          = "roles/compute.instanceAdmin"
  member        = "serviceAccount:service-${google_project.project.number}@compute-system.iam.gserviceaccount.com"
  # 19513753240@cloudservices.gserviceaccount.com
  # email   = "service-${var.project_id}@compute-system.iam.gserviceaccount.com"
}

# Allow the mongodb instance to self-destruct
resource "google_project_iam_member" "compute_instanceAdmin_v1" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.gce_mongodb.email}"
}
