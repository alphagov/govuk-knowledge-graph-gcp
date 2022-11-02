resource "google_compute_instance" "neo4j" {
  boot_disk {
    auto_delete = true
    device_name = "persistent-disk-0"

    initialize_params {
      image = "https://www.googleapis.com/compute/beta/projects/cos-cloud/global/images/cos-stable-101-17162-40-5"
      size  = 40
      type  = "pd-standard"
    }

    mode   = "READ_WRITE"
    source = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/zones/europe-west2-b/disks/neo4j"
  }

  machine_type = "e2-highmem-4"

  metadata = {
    gce-container-declaration = "\"spec\":\n  \"containers\":\n  - \"env\":\n    - \"name\": \"NEO4JLABS_PLUGINS\"\n      \"value\": \"[\\\"apoc\\\"]\"\n    \"image\": \"europe-west2-docker.pkg.dev/govuk-knowledge-graph/docker/neo4j:latest\"\n    \"stdin\": true\n    \"tty\": true\n  \"restartPolicy\": \"OnFailure\"\n  \"volumes\": []\n"
  }

  name = "neo4j"

  network_interface {
    access_config {
      nat_ip       = "34.105.209.240"
      network_tier = "PREMIUM"
    }

    network            = "https://www.googleapis.com/compute/v1/projects/govuk-knowledge-graph/global/networks/default"
    network_ip         = "10.154.0.3"
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

  service_account {
    email  = "gce-neo4j@govuk-knowledge-graph.iam.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_vtpm                 = true
  }

  zone = "europe-west2-b"
}
# terraform import google_compute_instance.neo4j projects/govuk-knowledge-graph/zones/europe-west2-b/instances/neo4j
