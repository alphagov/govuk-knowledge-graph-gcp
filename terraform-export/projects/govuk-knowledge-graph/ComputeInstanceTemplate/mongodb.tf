resource "google_compute_instance_template" "mongodb" {
  disk {
    auto_delete  = true
    boot         = true
    device_name  = "persistent-disk-0"
    disk_size_gb = 20
    disk_type    = "pd-standard"
    interface    = "SCSI"
    mode         = "READ_WRITE"
    source_image = "projects/cos-cloud/global/images/cos-stable-101-17162-40-5"
    type         = "PERSISTENT"
  }

  labels = {
    managed-by-cnrm = "true"
  }

  machine_type = "e2-highcpu-32"

  metadata = {
    gce-container-declaration = "\"spec\":\n  \"containers\":\n  - \"image\": \"europe-west2-docker.pkg.dev/govuk-knowledge-graph/docker/mongodb:latest\"\n    \"stdin\": true\n    \"tty\": true\n    \"volumeMounts\":\n    - \"mountPath\": \"/data/db\"\n      \"name\": \"tempfs-0\"\n      \"readOnly\": false\n    - \"mountPath\": \"/data/configdb\"\n      \"name\": \"tempfs-1\"\n      \"readOnly\": false\n  \"restartPolicy\": \"Never\"\n  \"volumes\":\n  - \"emptyDir\":\n      \"medium\": \"Memory\"\n    \"name\": \"tempfs-0\"\n  - \"emptyDir\":\n      \"medium\": \"Memory\"\n    \"name\": \"tempfs-1\"\n"
  }

  name = "mongodb"

  network_interface {
    access_config {
      nat_ip       = "35.214.119.84"
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
    email  = "gce-mongodb@govuk-knowledge-graph.iam.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
# terraform import google_compute_instance_template.mongodb projects/govuk-knowledge-graph/global/instanceTemplates/mongodb
