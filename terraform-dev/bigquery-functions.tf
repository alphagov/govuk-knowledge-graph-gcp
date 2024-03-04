# A dataset of user-defined functions and remote functions

resource "google_bigquery_dataset" "functions" {
  dataset_id            = "functions"
  friendly_name         = "functions"
  description           = "User-defined functions and remote functions"
  location              = "europe-west2"
  max_time_travel_hours = "48"
}

data "google_iam_policy" "bigquery_dataset_functions" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
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
    members = concat(
      [
        "projectReaders",
        google_service_account.gce_mongodb.member,
        google_service_account.bigquery_scheduled_queries.member,
      ],
      var.bigquery_functions_data_viewer_members,
    )
  }
}

resource "google_bigquery_dataset_iam_policy" "functions" {
  dataset_id  = google_bigquery_dataset.functions.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_functions.policy_data
}

resource "google_bigquery_routine" "libphonenumber_find_phone_numbers_in_text" {
  dataset_id   = google_bigquery_dataset.functions.dataset_id
  routine_id   = "libphonenumber_find_phone_numbers_in_text"
  routine_type = "SCALAR_FUNCTION"
  language     = "JAVASCRIPT"
  definition_body = templatefile(
    "bigquery/libphonenumber-find-phone-numbers-in-text.js",
    {
      project_id = var.project_id
    }
  )
  imported_libraries = [
    // From https://github.com/catamphetamine/libphonenumber-js
    "gs://${google_storage_bucket_object.libphonenumber.bucket}/${google_storage_bucket_object.libphonenumber.output_name}",
  ]
  return_type = jsonencode(
    {
      typeKind = "JSON"
    }
  )

  arguments {
    data_type = jsonencode(
      {
        typeKind = "STRING"
      }
    )
    name = "text"
  }
}

resource "google_bigquery_routine" "extract_phone_numbers" {
  dataset_id   = google_bigquery_dataset.functions.dataset_id
  routine_id   = "extract_phone_numbers"
  routine_type = "SCALAR_FUNCTION"
  language     = "SQL"
  definition_body = templatefile(
    "bigquery/extract-phone-numbers.sql",
    { project_id = var.project_id }
  )
  arguments {
    data_type = jsonencode(
      {
        typeKind = "STRING"
      }
    )
    name = "text"
  }
}

resource "google_bigquery_routine" "publishing_api_editions_current" {
  dataset_id      = google_bigquery_dataset.functions.dataset_id
  routine_id      = "publishing_api_editions_current"
  routine_type    = "PROCEDURE"
  language        = "SQL"
  definition_body = file("bigquery/publishing-api-editions-current.sql")
}

resource "google_bigquery_routine" "publishing_api_links_current" {
  dataset_id   = google_bigquery_dataset.functions.dataset_id
  routine_id   = "publishing_api_links_current"
  routine_type = "PROCEDURE"
  language     = "SQL"
  definition_body = file("bigquery/publishing-api-links-current.sql")
}

resource "google_bigquery_routine" "publishing_api_unpublishings_current" {
  dataset_id   = google_bigquery_dataset.functions.dataset_id
  routine_id   = "publishing_api_unpublishings_current"
  routine_type = "PROCEDURE"
  language     = "SQL"
  definition_body = file("bigquery/publishing-api-unpublishings-current.sql")
}

resource "google_bigquery_routine" "extract_content_from_editions" {
  dataset_id   = google_bigquery_dataset.functions.dataset_id
  routine_id   = "extract_content_from_editions"
  routine_type = "PROCEDURE"
  language     = "SQL"
  definition_body = templatefile(
    "bigquery/extract-content-from-editions.sql",
    { project_id = var.project_id, }
  )
}

resource "google_bigquery_routine" "taxonomy" {
  dataset_id   = google_bigquery_dataset.functions.dataset_id
  routine_id   = "taxonomy"
  routine_type = "PROCEDURE"
  language     = "SQL"
  definition_body = file("bigquery/taxonomy.sql")
}

resource "google_bigquery_routine" "contact_phone_numbers" {
  dataset_id   = google_bigquery_dataset.functions.dataset_id
  routine_id   = "contact_phone_numbers"
  routine_type = "PROCEDURE"
  language     = "SQL"
  definition_body = templatefile(
    "bigquery/contact-phone-numbers.sql",
    { project_id = var.project_id }
  )
}

resource "google_bigquery_routine" "phone_numbers" {
  dataset_id   = google_bigquery_dataset.functions.dataset_id
  routine_id   = "phone_numbers"
  routine_type = "PROCEDURE"
  language     = "SQL"
  definition_body = templatefile(
    "bigquery/phone-numbers.sql",
    { project_id = var.project_id }
  )
}
