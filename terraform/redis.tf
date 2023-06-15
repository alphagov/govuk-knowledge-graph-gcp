resource "google_redis_instance" "session_store" {
    name    =   "session-store"
    tier    =   "STANDARD_HA"
    memory_size_gb = 1
    region = var.region
    authorized_network = google_compute_network.cloudrun.name
    
    # Enable / Disable instance
    count = var.enable_redis_session_store_instance ? 1 : 0
}