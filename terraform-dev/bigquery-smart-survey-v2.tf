# # A dataset of data from the Smart Survey API

# resource "google_bigquery_dataset" "smart_survey_v2" {
#   dataset_id            = "smart_survey_v2"
#   friendly_name         = "Smart Survey"
#   description           = "Data from the Smart Survey v2 API"
#   location              = var.region
#   max_time_travel_hours = "48"
# }

# data "google_iam_policy" "bigquery_dataset_smart_survey_v2" {
#   binding {
#     role = "roles/bigquery.dataEditor"
#     members = [
#       "projectWriters",
#       google_service_account.workflow_smart_survey_v2.member,
#     ]
#   }
#   binding {
#     role = "roles/bigquery.dataOwner"
#     members = [
#       "projectOwners",
#     ]
#   }
#   binding {
#     role = "roles/bigquery.dataViewer"
#     members = concat(
#       [
#         "projectReaders",
#       ],
#       var.bigquery_smart_survey_v2_data_viewer_members,
#     )
#   }
# }

# resource "google_bigquery_dataset_iam_policy" "smart_survey_v2" {
#   dataset_id  = google_bigquery_dataset.smart_survey_v2.dataset_id
#   policy_data = data.google_iam_policy.bigquery_dataset_smart_survey_v2.policy_data
# }

# resource "google_bigquery_table" "smart_survey_responses_v2" {
#   dataset_id               = google_bigquery_dataset.smart_survey_v2.dataset_id
#   table_id                 = "responses"
#   friendly_name            = "Smart Survey v2 responses"
#   description              = "Survey responses from the Smart Survey v2 API, fetched by the smart-survey workflow."
#   schema                   = file("schemas/smart-survey-v2/responses.json")
#   require_partition_filter = true
#   time_partitioning {
#     expiration_ms = 1000 * 60 * 60 * 24 * 365
#     field         = "date_started"
#     type          = "DAY"
#   }
# }
