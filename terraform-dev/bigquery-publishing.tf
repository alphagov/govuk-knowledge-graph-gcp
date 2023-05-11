# A dataset of tables from the Publishing API postgres database

resource "google_bigquery_dataset" "publishing" {
  dataset_id            = "publishing"
  friendly_name         = "publishing"
  description           = "Data from the GOV.UK Publishing API database"
  location              = "europe-west2"
  max_time_travel_hours = "48"
}

data "google_iam_policy" "bigquery_dataset_publishing" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      "serviceAccount:${google_service_account.gce_postgres.email}",
    ]
  }
  binding {
    role = "roles/bigquery.dataOwner"
    members = [
      "projectOwners",
    ]
  }
  binding {
    role = "roles/bigquery.dataViewer"
    members = [
      "projectReaders",
      "group:data-engineering@digital.cabinet-office.gov.uk",
      "group:data-analysis@digital.cabinet-office.gov.uk",
      "group:data-products@digital.cabinet-office.gov.uk",
    ]
  }
}

resource "google_bigquery_dataset_iam_policy" "publishing" {
  dataset_id  = google_bigquery_dataset.publishing.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_publishing.policy_data
}

resource "google_bigquery_table" "publishing_actions" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "actions"
  friendly_name = "Actions"
  description   = "Actions table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "content_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "locale"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "action"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "user_uid"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "edition_id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "link_set_id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "event_id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_change_notes" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "change_notes"
  friendly_name = "Change notes"
  description   = "Change notes table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "note"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "public_timestamp"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "edition_id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_documents" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "documents"
  friendly_name = "Documents"
  description   = "Documents table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "content_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "locale"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "stale_lock_version"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "owning_document_id"
        type = "INTEGER"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_editions" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "editions"
  friendly_name = "Editions"
  description   = "Editions table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "title"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "public_updated_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "publishing_app"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "rendering_app"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "update_type"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "phase"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "analytics_identifier"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "document_type"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "schema_name"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "first_published_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "last_edited_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "state"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "user_facing_version"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "base_path"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "content_store"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "document_id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "description"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "publishing_request_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "major_published_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "published_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "publishing_api_first_published_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "publishing_api_last_edited_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "auth_bypass_ids"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "details"
        type = "JSON"
      },
      {
        mode = "NULLABLE"
        name = "routes"
        type = "JSON"
      },
      {
        mode = "NULLABLE"
        name = "redirects"
        type = "JSON"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_events" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "events"
  friendly_name = "Events"
  description   = "Events table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "action"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "user_uid"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "request_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "content_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "payload"
        type = "JSON"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_expanded_links" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "expanded_links"
  friendly_name = "Expanded links"
  description   = "Expanded links table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "content_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "locale"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "with_drafts"
        type = "BOOLEAN"
      },
      {
        mode = "NULLABLE"
        name = "payload_version"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "expanded_links"
        type = "JSON"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_link_changes" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "link_changes"
  friendly_name = "Link changes"
  description   = "Link changes table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "source_content_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "target_content_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "link_type"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "change"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "action_id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_link_sets" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "link_sets"
  friendly_name = "Link sets"
  description   = "Link sets table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "content_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "stale_lock_version"
        type = "INTEGER"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_links" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "links"
  friendly_name = "Links"
  description   = "Links table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "link_set_id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "target_content_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "link_type"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "position"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "edition_id"
        type = "INTEGER"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_path_reservations" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "path_reservations"
  friendly_name = "Path reservations"
  description   = "Path reservations table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "base_path"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "publishing_app"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_role_appointments" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "role_appointments"
  friendly_name = "Role appointments"
  description   = "Role appointments table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "url"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "content_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "details"
        type = "JSON"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_roles" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "roles"
  friendly_name = "Roles"
  description   = "Roles table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "url"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "schema_name"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "document_type"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "publishing_app"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "phase"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "content_id"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "locale"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "public_updated_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "first_published_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "base_path"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "title"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "description"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "details"
        type = "JSON"
      },
    ]
  )
}

resource "google_bigquery_table" "publishing_unpublishings" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "unpublishings"
  friendly_name = "Unpublishings"
  description   = "Unpublishings table from the GOV.UK Publishing API PostgreSQL database"
  schema = jsonencode(
    [
      {
        mode = "NULLABLE"
        name = "id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "edition_id"
        type = "INTEGER"
      },
      {
        mode = "NULLABLE"
        name = "type"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "explanation"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "alternative_path"
        type = "STRING"
      },
      {
        mode = "NULLABLE"
        name = "created_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "updated_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "unpublished_at"
        type = "TIMESTAMP"
      },
      {
        mode = "NULLABLE"
        name = "redirects"
        type = "JSON"
      },
    ]
  )
}
