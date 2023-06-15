resource "google_project_iam_binding" "redis_service_agent_binding" {
  project       = var.project_id
  role          = "roles/redis.serviceAgent"
  members       = ["serviceAccount:service-${var.project_number}@cloud-redis.iam.gserviceaccount.com"]
}


resource "google_redis_instance" "session_store" {
    name    =   "session-store"
    tier    =   "STANDARD_HA"
    memory_size_gb = 1
    region = var.region
    authorized_network = google_compute_network.cloudrun.name

    # Service account needs to be binded to this role before creating the instance
    depends_on = [google_project_iam_binding.redis_service_agent_binding]


    count = var.enable_redis_session_store_instance ? 1 : 0
}