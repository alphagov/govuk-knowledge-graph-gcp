# A dataset of tables for the govsearch app

resource "google_service_account" "bigquery_scheduled_queries_search" {
  account_id   = "bigquery-scheduled-search"
  display_name = "Bigquery scheduled queries for search"
  description  = "Service account for scheduled BigQuery queries for the 'search' dataset"
}

resource "google_bigquery_dataset" "search" {
  dataset_id            = "search"
  friendly_name         = "search"
  description           = "GOV.UK content data"
  location              = "europe-west2"
  max_time_travel_hours = "48"
}

data "google_iam_policy" "bigquery_dataset_search" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      "serviceAccount:${google_service_account.bigquery_scheduled_queries_search.email}",
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
      "serviceAccount:${google_service_account.govgraphsearch.email}",
    ]
  }
}

resource "google_bigquery_dataset_iam_policy" "search" {
  dataset_id  = google_bigquery_dataset.search.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_search.policy_data
}

resource "google_bigquery_table" "search_page" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "page"
  friendly_name = "Page table for the govsearch app"
  description   = "Page table for the govsearch app"
  schema        = <<EOF
[
  {
    "mode": "REQUIRED",
    "name": "url",
    "type": "STRING",
    "description": "URL of a page"
  },
  {
    "mode": "NULLABLE",
    "name": "documentType",
    "type": "STRING",
    "description": "The kind of thing that a page is about"
  },
  {
    "mode": "NULLABLE",
    "name": "contentId",
    "type": "STRING",
    "description": "The ID of the content item of a page"
  },
  {
    "mode": "NULLABLE",
    "name": "locale",
    "type": "STRING",
    "description": "The ISO 639-1 two-letter code of the language of an edition on GOV.UK"
  },
  {
    "mode": "NULLABLE",
    "name": "publishing_app",
    "type": "STRING",
    "description": "The application that published a content item on GOV.UK"
  },
  {
    "mode": "NULLABLE",
    "name": "first_published_at",
    "type": "TIMESTAMP",
    "description": "The date that a page was first published.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  },
  {
    "mode": "NULLABLE",
    "name": "public_updated_at",
    "type": "TIMESTAMP",
    "description": "When a page was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  },
  {
    "mode": "NULLABLE",
    "name": "withdrawn_at",
    "type": "TIMESTAMP",
    "description": "The date the page was withdrawn."
  },
  {
    "mode": "NULLABLE",
    "name": "withdrawn_explanation",
    "type": "STRING",
    "description": "The explanation for withdrawing a page"
  },
  {
    "mode": "NULLABLE",
    "name": "page_views",
    "type": "INTEGER",
    "description": "Number of page views from GA4 over 7 recent days"
  },
  {
    "mode": "NULLABLE",
    "name": "pagerank",
    "type": "BIGNUMERIC",
    "description": "Page rank of a page on GOV.UK"
  },
  {
    "mode": "NULLABLE",
    "name": "title",
    "type": "STRING",
    "description": "The title of a page"
  },
  {
    "mode": "NULLABLE",
    "name": "description",
    "type": "STRING",
    "description": "Description of a page"
  },
  {
    "mode": "NULLABLE",
    "name": "text",
    "type": "STRING",
    "description": "The content of the page as plain text extracted from the HTML"
  },
  {
    "mode": "REPEATED",
    "name": "taxons",
    "type": "STRING",
    "description": "Array of titles of taxons that the page is tagged to, and their ancestors"
  },
  {
    "mode": "NULLABLE",
    "name": "primary_organisation",
    "type": "STRING",
    "description": "Title of the primary organisation that published the page"
  },
  {
    "mode": "REPEATED",
    "name": "organisations",
    "type": "STRING",
    "description": "Array of titles of organisations that published the page"
  },
  {
    "mode": "REPEATED",
    "name": "hyperlinks",
    "type": "STRING",
    "description": "Array of hyperlinks from the body of the page"
  },
  {
    "mode": "REPEATED",
    "name": "entities",
    "type": "RECORD",
    "description": "Array of entity types and their frequency in the page",
    "fields": [
      {
        "name"        : "type",
        "type"        : "STRING",
        "description" : "The type of thing that the entity is"
      },
      {
        "name"        : "total_count",
        "type"        : "INTEGER",
        "description" : "The number of occurrences of entities of that type"
      }
    ]
  }
]
EOF
}

resource "google_bigquery_table" "search_person" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "person"
  friendly_name = "Person"
  description   = "Person table for the govsearch app"
  schema = jsonencode(
    [
      {
        name        = "name"
        type        = "STRING"
        description = "Name of the person"
      },
      {
        name        = "homepage"
        type        = "STRING"
        description = "URL of a page on GOV.UK about the person"
      },
      {
        name        = "description"
        type        = "STRING"
        description = "Description of the person"
      },
      {
        fields = [
          {
            name        = "title"
            type        = "STRING"
            description = "Title of the role"
          },
          {
            fields = [
              {
                name        = "orgName"
                type        = "STRING"
                description = "Name of the organisation"
              },
              {
                name        = "orgURL"
                type        = "STRING"
                description = "URL of a page on GOV.UK about the organisation"
              },
            ]
            mode        = "REPEATED"
            name        = "orgs"
            type        = "RECORD"
            description = "Array of organisations that the role relates to"
          },
          {
            name        = "startDate"
            type        = "TIMESTAMP"
            description = "When the person's appointment to the role began"
          },
          {
            name        = "endDate"
            type        = "TIMESTAMP"
            description = "When the person's appointment to the role ended"
          },
        ]
        mode        = "REPEATED"
        name        = "roles"
        type        = "RECORD"
        description = "Array of roles ever held by the person"
      },
    ]
  )
}

resource "google_bigquery_table" "search_organisation" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "organisation"
  friendly_name = "Organisation"
  description   = "Organisation table for the govsearch app"
  schema = jsonencode(
    [
      {
        name        = "name"
        type        = "STRING"
        description = "Name of the organisation"
      },
      {
        name        = "homepage"
        type        = "STRING"
        description = "URL of a page on GOV.UK about the organisation"
      },
      {
        name        = "parentName"
        type        = "STRING"
        description = "Name of the parent organisation of this organisation"
      },
      {
        mode        = "REPEATED"
        name        = "childOrgNames"
        type        = "STRING"
        description = "Array of names of organisations that are subsidiaries of this one"
      },
      {
        fields = [
          {
            name        = "roleName"
            type        = "STRING"
            description = "Title of the role"
          },
          {
            name        = "personName"
            type        = "STRING"
            description = "Name of the current appointee to this role"
          },
        ]
        mode        = "REPEATED"
        name        = "personRoleNames"
        type        = "RECORD"
        description = "Array of roles that relate to this organisation"
      },
      {
        mode        = "REPEATED"
        name        = "supersededBy"
        type        = "STRING"
        description = "Name of an organisation that superseded this one"
      },
      {
        mode        = "REPEATED"
        name        = "supersedes"
        type        = "STRING"
        description = "Array of names organisations that this one supersedes"
      },
    ]
  )
}

resource "google_bigquery_table" "search_role" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "role"
  friendly_name = "Role"
  description   = "Role table for the govsearch app"
  schema = jsonencode(
    [
      {
        name        = "name"
        type        = "STRING"
        description = "Name of the role"
      },
      {
        name        = "homepage"
        type        = "STRING"
        description = "URL of a page on GOV.UK about the role"
      },
      {
        name        = "description"
        type        = "STRING"
        description = "Description of the role"
      },
      {
        fields = [
          {
            name        = "name"
            type        = "STRING"
            description = "Name of the person"
          },
          {
            name        = "homepage"
            type        = "STRING"
            description = "URL of a page on GOV.UK about the person"
          },
          {
            name        = "startDate"
            type        = "TIMESTAMP"
            description = "Date when the person's appointment to the role began"
          },
          {
            name        = "endDate"
            type        = "TIMESTAMP"
            description = "Date when the person's appointment to the role ended"
          },
        ]
        mode        = "REPEATED"
        name        = "personNames"
        type        = "RECORD"
        description = "Array of people who have been appointed to this role"
      },
      {
        mode        = "REPEATED"
        name        = "orgNames"
        type        = "STRING"
        description = "Array of names organisations that the role relates to"
      },
    ]
  )
}

resource "google_bigquery_table" "search_taxon" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "taxon"
  friendly_name = "Taxon"
  description   = "Taxon table for the govsearch app"
  schema = jsonencode(
    [
      {
        name        = "name"
        type        = "STRING"
        description = "Name of the taxon"
      },
      {
        name        = "homepage"
        type        = "STRING"
        description = "URL of a page on GOV.UK about the taxon"
      },
      {
        name        = "description"
        type        = "STRING"
        description = "Description of the taxon"
      },
      {
        name        = "level"
        type        = "INTEGER"
        description = "Level of the taxon in the hierarchy. The root is level 0."
      },
      {
        fields = [
          {
            name        = "name"
            type        = "STRING"
            description = "Name of the taxon"
          },
          {
            name        = "level"
            type        = "INTEGER"
            description = "Level of the taxon in the hierarchy. The root is level 0."
          },
          {
            name        = "url"
            type        = "STRING"
            description = "URL of a page on GOV.UK about the taxon"
          },
        ]
        mode        = "REPEATED"
        name        = "ancestorTaxons"
        type        = "RECORD"
        description = "Array of ancestor taxons of this taxon"
      },
      {
        fields = [
          {
            name        = "name"
            type        = "STRING"
            description = "Name of the taxon"
          },
          {
            name        = "level"
            type        = "INTEGER"
            description = "Level of the taxon in the hierarchy. The root is level 0."
          },
          {
            name        = "url"
            type        = "STRING"
            description = "URL of a page on GOV.UK about the taxon"
          },
        ]
        mode        = "REPEATED"
        name        = "childTaxons"
        type        = "RECORD"
        description = "Array of child taxons of this taxon"
      },
    ]
  )
}

resource "google_bigquery_table" "search_transaction" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "transaction"
  friendly_name = "Transaction"
  description   = "Transaction table for the govsearch app"
  schema = jsonencode(
    [
      {
        name        = "name"
        type        = "STRING"
        description = "Name of the transaction"
      },
      {
        name        = "homepage"
        type        = "STRING"
        description = "URL of a page on GOV.UK about the transaction"
      },
      {
        name        = "description"
        type        = "STRING"
        description = "Description of the transaction"
      },
      {
        name        = "start_button_text"
        type        = "STRING"
        description = "Text of the start button"
      },
      {
        name        = "start_button_link"
        type        = "STRING"
        description = "The URL that the start button links to"
      },
    ]
  )
}

resource "google_bigquery_table" "search_bank_holiday" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "bank_holiday"
  friendly_name = "Bank holiday"
  description   = "Bank holiday table for the govsearch app"
  schema = jsonencode(
    [
      {
        name        = "name"
        type        = "STRING"
        description = "Name of the bank holiday"
      },
      {
        mode        = "REPEATED"
        name        = "divisions"
        type        = "STRING"
        description = "Array of names of divisions where the holiday occurs"
      },
      {
        mode        = "REPEATED"
        name        = "dates"
        type        = "DATE"
        description = "Array of dates when the holiday occurs"
      }
    ]
  )
}

resource "google_bigquery_table" "search_thing" {
  dataset_id    = google_bigquery_dataset.search.dataset_id
  table_id      = "thing"
  friendly_name = "Thing"
  description   = "Thing table for the govsearch app"
  schema = jsonencode(
    [
      {
        name        = "type"
        type        = "STRING"
        description = "Type of the thing"
      },
      {
        name        = "name"
        type        = "STRING"
        description = "Name of the thing"
      }
    ]
  )
}

# Because these queries are scheduled, without any way to manage their
# dependencies on source tables, they musn't use each other as a source.
resource "google_bigquery_data_transfer_config" "search_page" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Page"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/page.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_person" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Person"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/person.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_role" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Role"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/role.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_organisation" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Organisation"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/organisation.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_transation" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Transaction"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/transaction.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_taxon" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Taxon"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/taxon.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_bank_holiday" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Bank holiday"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/bank-holiday.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}

resource "google_bigquery_data_transfer_config" "search_thing" {
  data_source_id = "scheduled_query" # This is a magic word
  display_name   = "Thing"
  location       = var.region
  schedule       = "every day 06:00"
  params = {
    query = file("bigquery/thing.sql")
  }
  service_account_name = google_service_account.bigquery_scheduled_queries_search.email
}
