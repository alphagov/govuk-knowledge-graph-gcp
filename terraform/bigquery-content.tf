# A dataset of tables of GOV.UK content and related raw statistics

resource "google_bigquery_dataset" "content" {
  dataset_id            = "content"
  friendly_name         = "content"
  description           = "GOV.UK content data"
  location              = "europe-west2"
  max_time_travel_hours = "48"
}

data "google_iam_policy" "bigquery_dataset_content_dataEditor" {
  binding {
    role = "roles/bigquery.dataEditor"
    members = [
      "projectWriters",
      "serviceAccount:${google_service_account.gce_mongodb.email}",
      "serviceAccount:${google_service_account.gce_postgres.email}",
      "serviceAccount:${google_service_account.workflow_bank_holidays.email}",
      "serviceAccount:${google_service_account.bigquery_page_transitions.email}",
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
      "serviceAccount:ner-bulk-inference@cpto-content-metadata.iam.gserviceaccount.com",
      "serviceAccount:wif-ner-new-content-inference@cpto-content-metadata.iam.gserviceaccount.com",
      "serviceAccount:wif-govgraph-bigquery-access@govuk-llm-question-answering.iam.gserviceaccount.com",
      "serviceAccount:${google_service_account.bigquery_scheduled_queries_search.email}",
      "serviceAccount:${google_service_account.govgraphsearch.email}",
      "group:govsearch-data-viewers@digital.cabinet-office.gov.uk"
    ]
  }
}

resource "google_bigquery_dataset_iam_policy" "content" {
  dataset_id  = google_bigquery_dataset.content.dataset_id
  policy_data = data.google_iam_policy.bigquery_dataset_content_dataEditor.policy_data
}

resource "google_bigquery_table" "url" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "url"
  friendly_name = "GOV.UK unique URLs"
  description   = "Unique URLs of static content on the www.gov.uk domain, not including parts of 'guide' and 'travel_advice' pages, which are in the 'parts' table"
  schema        = file("schemas/content/url.json")
}

resource "google_bigquery_table" "phase" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "phase"
  friendly_name = "Service design phases"
  description   = "The service design phase of content items - https://www.gov.uk/service-manual/phases"
  schema        = file("schemas/content/phase.json")
}

resource "google_bigquery_table" "internal_name" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "internal_name"
  friendly_name = "GOV.UK content ID"
  description   = "Internal name of a taxon"
  schema        = file("schemas/content/internal-name.json")
}

resource "google_bigquery_table" "content_id" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "content_id"
  friendly_name = "GOV.UK content ID"
  description   = "IDs of static content on the www.gov.uk domain"
  schema        = file("schemas/content/content-id.json")
}

resource "google_bigquery_table" "analytics_identifier" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "analytics_identifier"
  friendly_name = "Analytics identifier"
  description   = "A short identifier we send to Google Analytics for multi-valued fields. This means we avoid the truncated values we would get if we sent the path or slug of eg organisations."
  schema        = file("schemas/content/analytics-identifier.json")
}

resource "google_bigquery_table" "acronym" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "acronym"
  friendly_name = "Acronym"
  description   = "The official acronym of an organisation on GOV.UK"
  schema        = file("schemas/content/acronym.json")
}

resource "google_bigquery_table" "document_type" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "document_type"
  friendly_name = "Document type"
  description   = "The kind of thing that a content item on GOV.UK represents"
  schema        = file("schemas/content/document-type.json")
}

resource "google_bigquery_table" "schema_name" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "schema_name"
  friendly_name = "Schema name"
  description   = "How the data of a content item is arranged"
  schema        = file("schemas/content/schema-name.json")
}

resource "google_bigquery_table" "locale" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "locale"
  friendly_name = "Locale"
  description   = "The ISO 639-1 two-letter code of the language of an edition on GOV.UK"
  schema        = file("schemas/content/locale.json")
}

resource "google_bigquery_table" "publishing_app" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "publishing_app"
  friendly_name = "Publishing app"
  description   = "The application that published a content item on GOV.UK"
  schema        = file("schemas/content/publishing-app.json")
}

resource "google_bigquery_table" "updated_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "updated_at"
  friendly_name = "Updated at date-time"
  description   = "When a content item was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  schema        = file("schemas/content/updated-at.json")
}

resource "google_bigquery_table" "public_updated_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "public_updated_at"
  friendly_name = "Public updated at date-time"
  description   = "When a content item was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  schema        = file("schemas/content/public-updated-at.json")
}

resource "google_bigquery_table" "first_published_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "first_published_at"
  friendly_name = "First published at date-time"
  description   = "The date the content was first published.  Automatically determined by the publishing-api, unless overridden by the publishing application."
  schema        = file("schemas/content/first-published-at.json")
}

resource "google_bigquery_table" "withdrawn_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "withdrawn_at"
  friendly_name = "Withdrawn at date-time"
  description   = "The date the content was withdrawn."
  schema        = file("schemas/content/withdrawn-at.json")
}

resource "google_bigquery_table" "withdrawn_explanation" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "withdrawn_explanation"
  friendly_name = "Withdrawn explanation date-time"
  description   = "The explanation for withdrawing the content."
  schema        = file("schemas/content/withdrawn-explanation.json")
}

resource "google_bigquery_table" "title" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "title"
  friendly_name = "Title"
  description   = "Titles of static content on the www.gov.uk domain, not including parts of 'guide' and 'travel_advice' pages, which are in the 'parts' table."
  schema        = file("schemas/content/title.json")
}

resource "google_bigquery_table" "description" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "description"
  friendly_name = "Description"
  description   = "Descriptions of static content on the www.gov.uk domain."
  schema        = file("schemas/content/description.json")
}

resource "google_bigquery_table" "department_analytics_profile" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "department_analytics_profile"
  friendly_name = "Department analytics profile"
  description   = "Analytics identifier with which to record views"
  schema        = file("schemas/content/department-analytics-profile.json")
}

resource "google_bigquery_table" "transaction_start_link" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "transaction_start_link"
  friendly_name = "Transaction start link"
  description   = "Link that the start button will link the user to"
  schema        = file("schemas/content/transaction-start-link.json")
}

resource "google_bigquery_table" "start_button_text" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "start_button_text"
  friendly_name = "Start-button text"
  description   = "Custom text to be displayed on the green button that leads you to another page"
  schema        = file("schemas/content/start-button-text.json")
}

resource "google_bigquery_table" "expanded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "expanded_links"
  friendly_name = "Expanded links"
  description   = "Typed relationships between two URLs, from one to the other"
  schema        = file("schemas/content/expanded-links.json")
}

resource "google_bigquery_table" "expanded_links_content_ids" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "expanded_links_content_ids"
  friendly_name = "Expanded links (content IDs)"
  description   = "Typed relationships between two content IDs, from one to the other"
  schema        = file("schemas/content/expanded-links-content-ids.json")
}

resource "google_bigquery_table" "parts" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "parts"
  friendly_name = "URLs and titles of parts of 'guide' and 'travel_advice' documents"
  description   = "URLs, base_paths, slugs, indexes and titles of parts of 'guide' and 'travel_advice' documents"
  schema        = file("schemas/content/parts.json")
}

resource "google_bigquery_table" "step_by_step_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "step_by_step_content"
  friendly_name = "Step-by-step content"
  description   = "Content of step-by-step pages"
  schema        = file("schemas/content/step-by-step-content.json")
}

resource "google_bigquery_table" "parts_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "parts_content"
  friendly_name = "Step-by-step content"
  description   = "Content of parts of 'guide' and 'travel_advice' documents"
  schema        = file("schemas/content/parts-content.json")
}

resource "google_bigquery_table" "transaction_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "transaction_content"
  friendly_name = "Transaction content"
  description   = "Content of 'transaction' documents"
  schema        = file("schemas/content/transaction-content.json")
}

resource "google_bigquery_table" "place_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "place_content"
  friendly_name = "Place content"
  description   = "Content of 'place' pages"
  schema        = file("schemas/content/place-content.json")
}

resource "google_bigquery_table" "body" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body"
  friendly_name = "Body content"
  description   = "Content of several types of pages, others are in tables with the suffix '_content'"
  schema        = file("schemas/content/body.json")
}

resource "google_bigquery_table" "body_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body_content"
  friendly_name = "Body content content"
  description   = "Content of several types of pages, others are in tables with the suffix '_content'"
  schema        = file("schemas/content/body-content.json")
}

resource "google_bigquery_table" "lines" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "lines"
  friendly_name = "Lines"
  description   = "Individual lines of content of pages"
  schema        = file("schemas/content/lines.json")
}

resource "google_bigquery_table" "step_by_step_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "step_by_step_embedded_links"
  friendly_name = "Step-by-step embedded links"
  description   = "Text and URLs of hyperlinks from the text of step-by-step pages"
  schema        = file("schemas/content/step-by-step-embedded-links.json")
}

resource "google_bigquery_table" "parts_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "parts_embedded_links"
  friendly_name = "Parts embedded links"
  description   = "Text and URLs of hyperlinks from the text of parts of 'guide' and 'travel_advice' documents"
  schema        = file("schemas/content/parts-embedded-links.json")
}

resource "google_bigquery_table" "transaction_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "transaction_embedded_links"
  friendly_name = "Transaction embedded links"
  description   = "Text and URLs of hyperlinks from the text of 'transaction' pages"
  schema        = file("schemas/content/transaction-embedded-links.json")
}

resource "google_bigquery_table" "place_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "place_embedded_links"
  friendly_name = "Place embedded links"
  description   = "Text and URLs of hyperlinks from the text of 'place' pages"
  schema        = file("schemas/content/place-embedded-links.json")
}

resource "google_bigquery_table" "body_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body_embedded_links"
  friendly_name = "Body embedded links"
  description   = "Text and URLs of hyperlinks from the text of several types of pages, others are in tables with the suffix '_embedded_links'"
  schema        = file("schemas/content/body-embedded-links.json")
}

resource "google_bigquery_table" "body_content_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body_content_embedded_links"
  friendly_name = "Body content embedded links"
  description   = "Text and URLs of hyperlinks from the text of several types of pages, others are in tables with the suffix '_embedded_links'"
  schema        = file("schemas/content/body-content-embedded-links.json")
}

resource "google_bigquery_table" "step_by_step_abbreviations" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "step_by_step_abbreviations"
  friendly_name = "Step-by-step abbreviations"
  description   = "Text and acronyms of abbreviations from the text of step-by-step pages"
  schema        = file("schemas/content/step-by-step-abbreviations.json")
}

resource "google_bigquery_table" "parts_abbreviations" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "parts_abbreviations"
  friendly_name = "Parts abbreviations"
  description   = "Text and acronyms of abbreviations from the text of parts of 'guide' and 'travel_advice' documents"
  schema        = file("schemas/content/parts-abbreviations.json")
}

resource "google_bigquery_table" "transaction_abbreviations" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "transaction_abbreviations"
  friendly_name = "Transaction abbreviations"
  description   = "Text and acronyms of abbreviations from the text of 'transaction' pages"
  schema        = file("schemas/content/transaction-abbreviations.json")
}

resource "google_bigquery_table" "place_abbreviations" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "place_abbreviations"
  friendly_name = "Place abbreviations"
  description   = "Text and acronyms of abbreviations from the text of 'place' pages"
  schema        = file("schemas/content/place-abbreviations.json")
}

resource "google_bigquery_table" "body_abbreviations" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body_abbreviations"
  friendly_name = "Body abbreviations"
  description   = "Text and acronyms of abbreviations from the text of several types of pages, others are in tables with the suffix '_abbreviations'"
  schema        = file("schemas/content/body-abbreviations.json")
}

resource "google_bigquery_table" "body_content_abbreviations" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "body_content_abbreviations"
  friendly_name = "Body content abbreviations"
  description   = "Text and acronyms from the text of several types of pages, others are in tables with the suffix '_abbreviations'"
  schema        = file("schemas/content/body-content-abbreviations.json")
}

resource "google_bigquery_table" "url_override" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "url_override"
  friendly_name = "URL override"
  description   = "A kind of redirect on GOV.UK.  Another is 'redirects'"
  schema        = file("schemas/content/url-override.json")
}

resource "google_bigquery_table" "redirect" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "redirects"
  friendly_name = "Redirects"
  description   = "A kind of redirect on GOV.UK. Another is 'url_override'"
  schema        = file("schemas/content/redirects.json")
}

resource "google_bigquery_table" "taxon_levels" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "taxon_levels"
  friendly_name = "Taxon levels"
  description   = "The level of each taxon in the hierarchy, with level 1 as the top"
  schema        = file("schemas/content/taxon-levels.json")
}

resource "google_bigquery_table" "appointment_current" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_current"
  friendly_name = "Appointment current"
  description   = "Whether a role appointment is current"
  schema        = file("schemas/content/appointment-current.json")
}

resource "google_bigquery_table" "appointment_ended_on" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_ended_on"
  friendly_name = "Appointment ended on"
  description   = "When an appointment to a role ended"
  schema        = file("schemas/content/appointment-ended-on.json")
}

resource "google_bigquery_table" "appointment_person" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_person"
  friendly_name = "Appointment person"
  description   = "The person appointed to a role"
  schema        = file("schemas/content/appointment-person.json")
}

resource "google_bigquery_table" "appointment_role" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_role"
  friendly_name = "Appointment role"
  description   = "The role that a person is appointed to"
  schema        = file("schemas/content/appointment-role.json")
}

resource "google_bigquery_table" "appointment_started_on" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_started_on"
  friendly_name = "Appointment started on"
  description   = "When an appointment to a role started"
  schema        = file("schemas/content/appointment-started-on.json")
}

resource "google_bigquery_table" "appointment_url" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "appointment_url"
  friendly_name = "Appointment url"
  description   = "Unique URLs of role appointments on GOV.UK"
  schema        = file("schemas/content/appointment-url.json")
}

resource "google_bigquery_table" "role_url" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_url"
  friendly_name = "Unique URLs of roles on GOV.UK"
  description   = "Unique URLs of roles on the www.gov.uk domain"
  schema        = file("schemas/content/role-url.json")
}

resource "google_bigquery_table" "role_content_id" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_content_id"
  friendly_name = "Role content ID"
  description   = "Content IDs of roles on GOV.UK"
  schema        = file("schemas/content/role-content-id.json")
}

resource "google_bigquery_table" "role_description" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_description"
  friendly_name = "Role description"
  description   = "Description of a role on GOV.UK"
  schema        = file("schemas/content/role-description.json")
}

resource "google_bigquery_table" "role_document_type" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_document_type"
  friendly_name = "Role document type"
  description   = "Document type of a role on GOV.UK"
  schema        = file("schemas/content/role-document-type.json")
}

resource "google_bigquery_table" "role_schema_name" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_schema_name"
  friendly_name = "Role document type"
  description   = "How the data of a role is arranged"
  schema        = file("schemas/content/role-schema-name.json")
}

resource "google_bigquery_table" "role_attends_cabinet_type" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_attends_cabinet_type"
  friendly_name = "Role attends cabinet type"
  description   = "Whether the incumbent of a role attends cabinet"
  schema        = file("schemas/content/role-attends-cabinet-type.json")
}

resource "google_bigquery_table" "role_homepage_url" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_homepage_url"
  friendly_name = "Role hompage URL"
  description   = "URL of the homepage of a role"
  schema        = file("schemas/content/role-homepage-url.json")
}

resource "google_bigquery_table" "role_content" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_content"
  friendly_name = "Role content"
  description   = "Content of 'role' pages"
  schema        = file("schemas/content/role-content.json")
}

resource "google_bigquery_table" "role_embedded_links" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_embedded_links"
  friendly_name = "Role embedded links"
  description   = "Text and URLs of hyperlinks from the text of 'role' pages"
  schema        = file("schemas/content/role-embedded-links.json")
}

resource "google_bigquery_table" "role_abbreviations" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_abbreviations"
  friendly_name = "Role abbreviations"
  description   = "Text and acronyms of abbreviations from the text of 'role' pages"
  schema        = file("schemas/content/role-abbreviations.json")
}

resource "google_bigquery_table" "role_locale" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_locale"
  friendly_name = "Role locale"
  description   = "Locale of a role"
  schema        = file("schemas/content/role-locale.json")
}

resource "google_bigquery_table" "role_first_published_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_first_published_at"
  friendly_name = "Role first published at"
  description   = "When a role was first published"
  schema        = file("schemas/content/role-first-published-at.json")
}

resource "google_bigquery_table" "role_phase" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_phase"
  friendly_name = "Role phase"
  description   = "Phase of a role"
  schema        = file("schemas/content/role-phase.json")
}

resource "google_bigquery_table" "role_public_updated_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_public_updated_at"
  friendly_name = "Role publicly updated at"
  description   = "When a role was publicly updated"
  schema        = file("schemas/content/role-public-updated-at.json")
}

resource "google_bigquery_table" "role_publishing_app" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_publishing_app"
  friendly_name = "Role publishing app"
  description   = "Publishing app of a role"
  schema        = file("schemas/content/role-publishing-app.json")
}

resource "google_bigquery_table" "role_redirect" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_redirect"
  friendly_name = "Role redirect"
  description   = "Redirects of homepates of roles"
  schema        = file("schemas/content/role-redirect.json")
}

resource "google_bigquery_table" "role_organisation" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_organisation"
  friendly_name = "Role organisation"
  description   = "Organisation to which a role belongs"
  schema        = file("schemas/content/role-organisation.json")
}

resource "google_bigquery_table" "role_payment_type" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_payment_type"
  friendly_name = "Role payment type"
  description   = "Payment type of roles"
  schema        = file("schemas/content/role-payment-type.json")
}

resource "google_bigquery_table" "role_seniority" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_seniority"
  friendly_name = "Role seniority"
  description   = "Seniority of roles"
  schema        = file("schemas/content/role-seniority.json")
}

resource "google_bigquery_table" "role_title" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_title"
  friendly_name = "Role title"
  description   = "Title of roles"
  schema        = file("schemas/content/role-title.json")
}

resource "google_bigquery_table" "role_updated_at" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_updated_at"
  friendly_name = "Role updated at"
  description   = "When a role was updated"
  schema        = file("schemas/content/role-updated-at.json")
}

resource "google_bigquery_table" "role_whip_organisation" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "role_whip_organisation"
  friendly_name = "Role whip organisation"
  description   = "Whip organisation of roles"
  schema        = file("schemas/content/role-whip-organisation.json")
}

resource "google_bigquery_table" "bank_holiday_raw" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "bank_holiday_raw"
  friendly_name = "UK Bank Holiday raw JSON data"
  description   = "UK Bank Holiday raw JSON data"
  schema        = file("schemas/content/bank-holiday-raw.json")
}

resource "google_bigquery_table" "bank_holiday_occurrence" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "bank_holiday_occurrence"
  friendly_name = "UK Bank Holiday occurrences"
  description   = "UK Bank Holiday occurrences"
  schema        = file("schemas/content/bank-holiday-occurrence.json")
}

resource "google_bigquery_table" "bank_holiday_url" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "bank_holiday_url"
  friendly_name = "Bank holiday URL"
  description   = "Unique URLs of UK bank holidays"
  schema        = file("schemas/content/bank-holiday-url.json")
}

resource "google_bigquery_table" "bank_holiday_title" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "bank_holiday_title"
  friendly_name = "Bank holiday title"
  description   = "Titles of UK bank holidays"
  schema        = file("schemas/content/bank-holiday-title.json")
}

resource "google_bigquery_table" "page_views" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "page_views"
  friendly_name = "Page views"
  description   = "Number of views of GOV.UK pages over 7 days"
  schema        = file("schemas/content/page-views.json")
}

resource "google_bigquery_table" "content_items" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "content_items"
  friendly_name = "Content items"
  description   = "The raw JSON from the MongoDB Content Store database"
  schema        = file("schemas/content/content-items.json")
}

resource "google_bigquery_table" "organisation_govuk_status" {
  dataset_id    = google_bigquery_dataset.content.dataset_id
  table_id      = "organisation_govuk_status"
  friendly_name = "Organisation GOV.UK status"
  description   = "The status of the organisation in GOV.UK"
  schema        = file("schemas/content/organisation-govuk-status.json")
}

resource "google_bigquery_table" "abbreviations" {
  dataset_id    = "content"
  table_id      = "abbreviations"
  friendly_name = "Abbreviations"
  description   = "Abbreviations defined on GOV.UK pages"
  schema        = file("schemas/content/abbreviations.json")
}
