resource "google_compute_instance_template" "neo4j" {
  disk {
    auto_delete  = true
    boot         = true
    device_name  = "persistent-disk-0"
    disk_size_gb = 40
    disk_type    = "pd-standard"
    interface    = "SCSI"
    mode         = "READ_WRITE"
    source_image = "projects/cos-cloud/global/images/cos-stable-101-17162-40-5"
    type         = "PERSISTENT"
  }

  labels = {
    managed-by-cnrm = "true"
  }

  machine_type = "e2-highmem-4"

  metadata = {
    gce-container-declaration = "\"spec\":\n  \"containers\":\n  - \"env\":\n    - \"name\": \"NEO4JLABS_PLUGINS\"\n      \"value\": \"[\\\"apoc\\\"]\"\n    \"image\": \"europe-west2-docker.pkg.dev/govuk-knowledge-graph/docker/neo4j:latest\"\n    \"stdin\": true\n    \"tty\": true\n  \"restartPolicy\": \"OnFailure\"\n  \"volumes\": []\n"
  }

  name = "neo4j"

  network_interface {
    access_config {
      nat_ip       = "34.105.179.197"
      network_tier = "PREMIUM"
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
    email  = "gce-neo4j@govuk-knowledge-graph.iam.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["allow-health-check"]
}
# terraform import google_compute_instance_template.neo4j projects/govuk-knowledge-graph/global/instanceTemplates/neo4j
