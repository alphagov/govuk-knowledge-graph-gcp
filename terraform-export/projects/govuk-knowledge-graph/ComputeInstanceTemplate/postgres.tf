resource "google_compute_instance_template" "postgres" {
  disk {
    auto_delete  = true
    boot         = true
    device_name  = "persistent-disk-0"
    disk_size_gb = 10
    disk_type    = "pd-standard"
    interface    = "SCSI"
    mode         = "READ_WRITE"
    source_image = "projects/cos-cloud/global/images/cos-stable-101-17162-40-5"
    type         = "PERSISTENT"
  }

  disk {
    auto_delete  = true
    device_name  = "local-ssd"
    disk_size_gb = 375
    disk_type    = "local-ssd"
    interface    = "NVME"
    mode         = "READ_WRITE"
    type         = "SCRATCH"
  }

  labels = {
    managed-by-cnrm = "true"
  }

  machine_type = "c2d-highmem-2"

  metadata = {
    gce-container-declaration = "\"spec\":\n  \"containers\":\n  - \"env\":\n    - \"name\": \"POSTGRES_HOST_AUTH_METHOD\"\n      \"value\": \"trust\"\n    \"image\": \"europe-west2-docker.pkg.dev/govuk-knowledge-graph/docker/postgres:latest\"\n    \"stdin\": true\n    \"tty\": true\n    \"volumeMounts\":\n    - \"mountPath\": \"/var/lib/postgresql/data\"\n      \"name\": \"local-ssd-postgresql-data\"\n      \"readOnly\": false\n    - \"mountPath\": \"/data\"\n      \"name\": \"local-ssd-data\"\n      \"readOnly\": false\n  \"restartPolicy\": \"Never\"\n  \"volumes\":\n  - \"hostPath\":\n      \"path\": \"/mnt/disks/local-ssd/postgresql-data\"\n    \"name\": \"local-ssd-postgresql-data\"\n  - \"hostPath\":\n      \"path\": \"/mnt/disks/local-ssd/data\"\n    \"name\": \"local-ssd-data\"\n"
    user-data                 = "#cloud-config\n\nbootcmd:\n- mkfs.ext4 -F /dev/nvme0n1\n- mkdir -p /mnt/disks/local-ssd\n- mount -o discard,defaults,nobarrier /dev/nvme0n1 /mnt/disks/local-ssd\n- mkdir -p /mnt/disks/local-ssd/postgresql-data\n- mkdir -p /mnt/disks/local-ssd/data\n"
  }

  name = "postgres"

  network_interface {
    access_config {
      network_tier = "STANDARD"
    }

    network = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/networks/default"
  }

  project = "govuk-knowledge-graph"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "gce-postgres@govuk-knowledge-graph.iam.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
# terraform import google_compute_instance_template.postgres projects/govuk-knowledge-graph/global/instanceTemplates/postgres
