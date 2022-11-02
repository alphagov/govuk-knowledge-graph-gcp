resource "google_compute_instance" "postgres" {
  boot_disk {
    auto_delete = true
    device_name = "persistent-disk-0"

    initialize_params {
      image = "https://www.googleapis.com/compute/beta/projects/cos-cloud/global/images/cos-stable-101-17162-40-5"
      size  = 10
      type  = "pd-standard"
    }

    mode   = "READ_WRITE"
    source = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/zones/europe-west2-b/disks/postgres"
  }

  machine_type = "c2d-highmem-2"

  metadata = {
    object_bucket             = "govuk-s3-mirror_govuk-integration-database-backups"
    user-data                 = "#cloud-config\n\nbootcmd:\n- mkfs.ext4 -F /dev/nvme0n1\n- mkdir -p /mnt/disks/local-ssd\n- mount -o discard,defaults,nobarrier /dev/nvme0n1 /mnt/disks/local-ssd\n- mkdir -p /mnt/disks/local-ssd/postgresql-data\n- mkdir -p /mnt/disks/local-ssd/data\n"
    gce-container-declaration = "\"spec\":\n  \"containers\":\n  - \"env\":\n    - \"name\": \"POSTGRES_HOST_AUTH_METHOD\"\n      \"value\": \"trust\"\n    \"image\": \"europe-west2-docker.pkg.dev/govuk-knowledge-graph/docker/postgres:latest\"\n    \"stdin\": true\n    \"tty\": true\n    \"volumeMounts\":\n    - \"mountPath\": \"/var/lib/postgresql/data\"\n      \"name\": \"local-ssd-postgresql-data\"\n      \"readOnly\": false\n    - \"mountPath\": \"/data\"\n      \"name\": \"local-ssd-data\"\n      \"readOnly\": false\n  \"restartPolicy\": \"Never\"\n  \"volumes\":\n  - \"hostPath\":\n      \"path\": \"/mnt/disks/local-ssd/postgresql-data\"\n    \"name\": \"local-ssd-postgresql-data\"\n  - \"hostPath\":\n      \"path\": \"/mnt/disks/local-ssd/data\"\n    \"name\": \"local-ssd-data\"\n"
    object_name               = "publishing-api-postgres/2022-09-29T05:00:02-publishing_api_production.gz"
  }

  name = "postgres"

  network_interface {
    access_config {
      nat_ip       = "35.214.84.153"
      network_tier = "STANDARD"
    }

    network            = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/networks/default"
    network_ip         = "10.154.0.4"
    stack_type         = "IPV4_ONLY"
    subnetwork         = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/regions/europe-west2/subnetworks/default"
    subnetwork_project = "govuk-knowledge-graph"
  }

  project = "govuk-knowledge-graph"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  scratch_disk {
    interface = "NVME"
  }

  service_account {
    email  = "gce-postgres@govuk-knowledge-graph.iam.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_vtpm                 = true
  }

  zone = "europe-west2-b"
}
# terraform import google_compute_instance.postgres projects/govuk-knowledge-graph/zones/europe-west2-b/instances/postgres
