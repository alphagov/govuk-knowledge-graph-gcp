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

resource "google_service_account" "gce_content" {
  account_id   = "gce-content"
  display_name = "Service Account for the Content Store postgres instance"
  description  = "Service Account for the Content Store postgres instance on GCE"
}

resource "google_service_account" "gce_redis_cli" {
  account_id   = "gce-redis-cli"
  display_name = "Service Account for the Redis CLI instance"
  description  = "Service Account for the Redis CLI instance on GCE"
}

# Allow a workflow to attach the mongodb service account to an instance.
data "google_iam_policy" "service_account-gce_mongodb" {
  binding {
    role = "roles/iam.serviceAccountUser"
    members = [
      google_service_account.workflow_govuk_integration_database_backups.member,
      google_service_account.gce_content.member,
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
      google_service_account.workflow_govuk_integration_database_backups.member,
    ]
  }
}

resource "google_service_account_iam_policy" "gce_postgres" {
  service_account_id = google_service_account.gce_postgres.name
  policy_data        = data.google_iam_policy.service_account-gce_postgres.policy_data
}

# Allow a workflow to attach the content service account to an instance.
data "google_iam_policy" "service_account-gce_content" {
  binding {
    role = "roles/iam.serviceAccountUser"
    members = [
      google_service_account.workflow_govuk_integration_database_backups.member,
    ]
  }
}

resource "google_service_account_iam_policy" "gce_content" {
  service_account_id = google_service_account.gce_content.name
  policy_data        = data.google_iam_policy.service_account-gce_content.policy_data
}

# Allow a workflow to attach the redis-cli service account to an instance.
data "google_iam_policy" "service_account-gce_redis_cli" {
  binding {
    role = "roles/iam.serviceAccountUser"
    members = [
      google_service_account.workflow_redis_cli.member,
    ]
  }
}

resource "google_service_account_iam_policy" "gce_redis_cli" {
  service_account_id = google_service_account.gce_redis_cli.name
  policy_data        = data.google_iam_policy.service_account-gce_redis_cli.policy_data
}

# terraform import google_compute_network.default default
resource "google_compute_network" "default" {
  name        = "default"
  description = "Default network for the project"
}

# Network for GovGraph Search
resource "google_compute_network" "cloudrun" {
  name                            = "custom-vpc-for-cloud-run"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = false
  enable_ula_internal_ipv6        = false
  mtu                             = 1460
  project                         = var.project_id
  routing_mode                    = "REGIONAL"
}

# Subnet for GovGraph Search
resource "google_compute_subnetwork" "cloudrun" {
  name                       = "cloudrun-subnet"
  ip_cidr_range              = "10.8.0.0/28"
  network                    = google_compute_network.cloudrun.id
  private_ip_google_access   = true # otherwise containers won't start
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = var.project_id
  purpose                    = "PRIVATE"
  region                     = "europe-west2"
  stack_type                 = "IPV4_ONLY"
}

# https://github.com/terraform-google-modules/terraform-google-container-vm
module "mongodb-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = "europe-west2-docker.pkg.dev/${var.project_id}/docker/mongodb:latest"
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
    env = [
      {
        name  = "PROJECT_ID"
        value = var.project_id
      },
      {
        name  = "ZONE"
        value = var.zone
      }
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
    image = "europe-west2-docker.pkg.dev/${var.project_id}/docker/postgres:latest"
    tty : true
    stdin : true
    securityContext = {
      privileged : true
    }
    env = [
      {
        name  = "POSTGRES_HOST_AUTH_METHOD"
        value = "trust"
      },
      {
        name  = "PROJECT_ID"
        value = var.project_id
      },
      {
        name  = "ZONE"
        value = var.zone
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

# https://github.com/terraform-google-modules/terraform-google-container-vm
module "content-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  container = {
    image = "europe-west2-docker.pkg.dev/${var.project_id}/docker/content:latest"
    tty : true
    stdin : true
    securityContext = {
      privileged : true
    }
    env = [
      {
        name  = "POSTGRES_HOST_AUTH_METHOD"
        value = "trust"
      },
      {
        name  = "PROJECT_ID"
        value = var.project_id
      },
      {
        name  = "ZONE"
        value = var.zone
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

# https://github.com/terraform-google-modules/terraform-google-container-vm
module "redis-cli-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 2.0"

  # Enable / Disable
  count = var.enable_redis_session_store_instance ? 1 : 0

  container = {
    image = "europe-west2-docker.pkg.dev/${var.project_id}/docker/redis-cli:latest"
    tty : true
    stdin : true
    env = [
      {
        name  = "PROJECT_ID"
        value = var.project_id
      },
      {
        name  = "REGION"
        value = var.region
      },
      {
        name  = "ZONE"
        value = var.zone
      },
      {
        name  = "REDIS_HOST"
        value = google_redis_instance.session_store[0].host
      },
      {
        name  = "REDIS_PORT"
        value = google_redis_instance.session_store[0].port
      }
    ]
  }


  restart_policy = "Never"
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
    google-logging-enabled     = true
    serial-port-logging-enable = true
    gce-container-declaration  = module.mongodb-container.metadata_value
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
    user-data                  = var.postgres-startup-script
    google-logging-enabled     = true
    serial-port-logging-enable = true
    gce-container-declaration  = module.postgres-container.metadata_value
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

resource "google_compute_instance_template" "content" {
  name = "content"
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
    user-data                  = var.postgres-startup-script
    google-logging-enabled     = true
    serial-port-logging-enable = true
    gce-container-declaration  = module.postgres-container.metadata_value
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
    }
  }

  service_account {
    email  = google_service_account.gce_content.email
    scopes = ["cloud-platform"]
  }
}

# Template for occasional use, such as debugging
resource "google_compute_instance_template" "redis_cli" {
  name         = "redis-cli"
  machine_type = "e2-medium"

  # Enable / Disable
  count = var.enable_redis_session_store_instance ? 1 : 0

  disk {
    boot         = true
    source_image = module.redis-cli-container[0].source_image
    disk_size_gb = 10
  }

  metadata = {
    google-logging-enabled     = true
    serial-port-logging-enable = true
    gce-container-declaration  = module.redis-cli-container[0].metadata_value
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
    }
  }

  service_account {
    email  = google_service_account.gce_redis_cli.email
    scopes = ["cloud-platform"]
  }
}

# Project-level metadata, on all machines
resource "google_compute_project_metadata" "default" {
  metadata = {
    google-logging-enabled     = true
    serial-port-logging-enable = true
  }
}

resource "google_compute_firewall" "custom_vpc_for_cloud_run_allow_iap_ssh" {
  name        = "custom-vpc-for-cloud-run-allow-iap-ssh"
  description = "Allow ingress via IAP"
  network     = google_compute_network.cloudrun.name
  priority    = 65534

  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_service_accounts = [
    google_service_account.gce_redis_cli.email
  ]
}
