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
      google_service_account.gce_postgres.member,
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
      "group:govsearch-data-viewers@digital.cabinet-office.gov.uk",
      google_service_account.bigquery_scheduled_queries_search.member,
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
  schema        = file("schemas/publishing/actions.json")
}

resource "google_bigquery_table" "publishing_change_notes" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "change_notes"
  friendly_name = "Change notes"
  description   = "Change notes table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/change-notes.json")
  range_partitioning {
    field = "edition_id"
    range {
      start = 0
      end = 100000000 # 10 times the maximum edition_id at the end of 2023, which was about 10000000
      interval = 25000 # 4k partitions, which is the limit
    }
  }
}

resource "google_bigquery_table" "publishing_documents" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "documents"
  friendly_name = "Documents"
  description   = "Documents table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/documents.json")
  range_partitioning {
    field = "id"
    range {
      start = 0
      end = 15000000 # 10 times the maximum at the end of 2023, which was about 1500000
      interval = 3750 # 4k partitions, which is the limit
    }
  }
}

resource "google_bigquery_table" "publishing_editions" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "editions"
  friendly_name = "Editions"
  description   = "Editions table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/editions.json")
  time_partitioning {
    type = "MONTH" # DAY would exceed of 4k partitions (max allowable)
    field = "updated_at"
  }
}

resource "google_bigquery_table" "publishing_events" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "events"
  friendly_name = "Events"
  description   = "Events table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/events.json")
}

resource "google_bigquery_table" "publishing_expanded_links" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "expanded_links"
  friendly_name = "Expanded links"
  description   = "Expanded links table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/expanded-links.json")
}

resource "google_bigquery_table" "publishing_link_changes" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "link_changes"
  friendly_name = "Link changes"
  description   = "Link changes table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/link-changes.json")
}

resource "google_bigquery_table" "publishing_link_sets" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "link_sets"
  friendly_name = "Link sets"
  description   = "Link sets table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/link-sets.json")
  # No partition, because joins are by content_id, a string, which isn't supported
}

resource "google_bigquery_table" "publishing_links" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "links"
  friendly_name = "Links"
  description   = "Links table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/links.json")
  range_partitioning {
    field = "link_set_id"
    range {
      start = 0
      end = 10000000 # 10 times the maximum at the end of 2023, which was about 1000000
      interval = 2500 # 4k partitions, which is the limit
    }
  }
}

resource "google_bigquery_table" "publishing_path_reservations" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "path_reservations"
  friendly_name = "Path reservations"
  description   = "Path reservations table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/path-reservations.json")
}

resource "google_bigquery_table" "publishing_role_appointments" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "role_appointments"
  friendly_name = "Role appointments"
  description   = "Role appointments table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/role-appointments.json")
}

resource "google_bigquery_table" "publishing_roles" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "roles"
  friendly_name = "Roles"
  description   = "Roles table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/roles.json")
}

resource "google_bigquery_table" "publishing_unpublishings" {
  dataset_id    = google_bigquery_dataset.publishing.dataset_id
  table_id      = "unpublishings"
  friendly_name = "Unpublishings"
  description   = "Unpublishings table from the GOV.UK Publishing API PostgreSQL database"
  schema        = file("schemas/publishing/unpublishings.json")
  range_partitioning {
    field = "edition_id"
    range {
      start = 0
      end = 100000000 # 10 times the maximum edition_id at the end of 2023, which was about 10000000
      interval = 25000 # 4k partitions, which is the limit
    }
  }
}
