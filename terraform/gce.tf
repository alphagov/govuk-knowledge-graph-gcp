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

resource "google_service_account" "gce_postgres" {
  account_id   = "gce-postgres"
  display_name = "Service Account for postgres Instance"
  description  = "Service account for the postgres instance on GCE"
}

# Allow a workflow to attach the mongodb service account to an instance.
data "google_iam_policy" "service_account-gce_mongodb" {
  binding {
    role = "roles/iam.serviceAccountUser"
    members = [
      "serviceAccount:${google_service_account.workflow_govuk_integration_database_backups.email}",
    ]
  }
}

resource "google_service_account_iam_policy" "gce_mongodb" {
  service_account_id = google_service_account.gce_mongodb.name
  policy_data        = data.google_iam_policy.service_account-gce_mongodb.policy_data
}

# Allow a workflow to attach the postgres service account to an instance.
data "google_iam_policy" "service_account-gce_postgres" {
  binding {
    role = "roles/iam.serviceAccountUser"
    members = [
      "serviceAccount:${google_service_account.workflow_govuk_integration_database_backups.email}",
    ]
  }
}

resource "google_service_account_iam_policy" "gce_postgres" {
  service_account_id = google_service_account.gce_postgres.name
  policy_data        = data.google_iam_policy.service_account-gce_postgres.policy_data
}

# Allow a workflow to attach the neo4j service account to an instance.
data "google_iam_policy" "service_account-gce_neo4j" {
  binding {
    role = "roles/iam.serviceAccountUser"
    members = [
      "serviceAccount:${google_service_account.workflow_neo4j.email}",
    ]
  }
}

resource "google_service_account_iam_policy" "gce_neo4j" {
  service_account_id = google_service_account.gce_neo4j.name
  policy_data        = data.google_iam_policy.service_account-gce_neo4j.policy_data
}

# terraform import google_compute_network.default default
resource "google_compute_network" "default" {
  name        = "default"
  description = "Default network for the project"
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

# Network for Neo4j and GovGraph Search
resource "google_compute_network" "cloudrun" {
    name                            = "custom-vpc-for-cloud-run"
    auto_create_subnetworks         = false
    delete_default_routes_on_create = false
    enable_ula_internal_ipv6        = false
    mtu                             = 1460
    project                         = "govuk-knowledge-graph"
    routing_mode                    = "REGIONAL"
}

# Subnet for Neo4j and GovGraph Search
resource "google_compute_subnetwork" "cloudrun" {
    name                       = "cloudrun-subnet"
    ip_cidr_range              = "10.8.0.0/28"
    network = google_compute_network.cloudrun.id
    private_ip_google_access   = false
    private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
    project                    = "govuk-knowledge-graph"
    purpose                    = "PRIVATE"
    region                     = "europe-west2"
    stack_type                 = "IPV4_ONLY"
}

# Static, internal IP address
resource "google_compute_address" "neo4j_internal" {
  name = "neo4j-internal"
  address_type = "INTERNAL"
  subnetwork = google_compute_subnetwork.cloudrun.id
}

# https://github.com/terraform-google-modules/terraform-google-container-vm
module "neo4j-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = "europe-west2-docker.pkg.dev/govuk-knowledge-graph/docker/neo4j:latest"
    tty : true
    stdin : true
    env = [
      {
        name  = "NEO4JLABS_PLUGINS"
        value = "[\"apoc\"]"
      }
    ]
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
    volumeMounts = [
      {
        mountPath = "/data/db"
        name      = "tempfs-0"
        readOnly  = false
      },
      {
        mountPath = "/data/configdb"
        name      = "tempfs-1"
        readOnly  = false
      },
    ]
  }

  # Declare the Volumes which will be used for mounting.
  volumes = [
    {
      name = "tempfs-0"

      emptyDir = {
        medium = "Memory"
      }
    },
    {
      name = "tempfs-1"

      emptyDir = {
        medium = "Memory"
      }
    },
  ]

  restart_policy = "Never"
}

# https://github.com/terraform-google-modules/terraform-google-container-vm
module "postgres-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = "europe-west2-docker.pkg.dev/govuk-knowledge-graph/docker/postgres:latest"
    tty : true
    stdin : true
    env = [
      {
        name  = "POSTGRES_HOST_AUTH_METHOD"
        value = "trust"
      }
    ]
    volumeMounts = [
      {
        mountPath = "/var/lib/postgresql/data"
        name      = "local-ssd-postgresql-data"
        readOnly  = false
      },
      {
        mountPath = "/data"
        name      = "local-ssd-data"
        readOnly  = false
      }
    ]
  }

  volumes = [
    # https://github.com/terraform-google-modules/terraform-google-container-vm/issues/66
    {
      name = "local-ssd-postgresql-data"
      hostPath = {
        path = "/mnt/disks/local-ssd/postgresql-data"
      }
    },
    {
      name = "local-ssd-data"
      hostPath = {
        path = "/mnt/disks/local-ssd/data"
      }
    }
  ]

  restart_policy = "Never"
}

resource "google_compute_instance_template" "neo4j" {
  name         = "neo4j"
  machine_type = "e2-highmem-16"

  disk {
    boot         = true
    source_image = module.neo4j-container.source_image
    disk_size_gb = 40
  }

  metadata = {
    gce-container-declaration = module.neo4j-container.metadata_value
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
    }
  }

  service_account {
    email  = google_service_account.gce_neo4j.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance_template" "mongodb" {
  name         = "mongodb"
  machine_type = "e2-highcpu-32"

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
    }
  }

  service_account {
    email  = google_service_account.gce_mongodb.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance_template" "postgres" {
  name = "postgres"
  # 2 CPUs are enough that, while the largest table is being restored, all the
  # other tables will also be restored, even if some of them are done in series
  # rather than parallel.  Not much memory is required.  See postgresql.conf for
  # the memory allowances.
  machine_type = "c2d-highmem-2"

  disk {
    boot         = true
    source_image = module.postgres-container.source_image
    disk_size_gb = 10
  }

  disk {
    device_name  = "local-ssd"
    interface    = "NVME"
    disk_type    = "local-ssd"
    disk_size_gb = "375" # Must be exactly 375GB for a local SSD disk
    type         = "SCRATCH"
  }

  metadata = {
    # https://cloud.google.com/container-optimized-os/docs/concepts/disks-and-filesystem#mounting_and_formatting_disks
    user-data                 = var.postgres-startup-script
    gce-container-declaration = module.postgres-container.metadata_value
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
    }
  }

  service_account {
    email  = google_service_account.gce_postgres.email
    scopes = ["cloud-platform"]
  }
}
