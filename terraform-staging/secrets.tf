resource "google_secret_manager_secret" "smart_survey_api_survey_id" {
  secret_id = "smart-survey-api-survey-id"
  replication {
    auto {}
  }
}

data "google_iam_policy" "secret_smart_survey_api_survey_id" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      google_service_account.workflow_smart_survey.member,
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "smart_survey_api_survey_id" {
  secret_id   = google_secret_manager_secret.smart_survey_api_survey_id.secret_id
  policy_data = data.google_iam_policy.secret_smart_survey_api_survey_id.policy_data
}

resource "google_secret_manager_secret" "smart_survey_api_token" {
  secret_id = "smart-survey-api-token"
  replication {
    auto {}
  }
}

data "google_iam_policy" "secret_smart_survey_api_token" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      google_service_account.workflow_smart_survey.member,
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "smart_survey_api_token" {
  secret_id   = google_secret_manager_secret.smart_survey_api_token.secret_id
  policy_data = data.google_iam_policy.secret_smart_survey_api_token.policy_data
}

resource "google_secret_manager_secret" "smart_survey_api_secret" {
  secret_id = "smart-survey-api-secret"
  replication {
    auto {}
  }
}

data "google_iam_policy" "secret_smart_survey_api_secret" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      google_service_account.workflow_smart_survey.member,
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "smart_survey_api_secret" {
  secret_id   = google_secret_manager_secret.smart_survey_api_secret.secret_id
  policy_data = data.google_iam_policy.secret_smart_survey_api_secret.policy_data
}

resource "google_secret_manager_secret" "zendesk_user_email" {
  secret_id = "zendesk-user-email"
  replication {
    auto {}
  }
}

data "google_iam_policy" "secret_zendesk_user_email" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      google_service_account.workflow_zendesk.member,
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "zendesk_user_email" {
  secret_id   = google_secret_manager_secret.zendesk_user_email.secret_id
  policy_data = data.google_iam_policy.secret_zendesk_user_email.policy_data
}

resource "google_secret_manager_secret" "zendesk_subdomain" {
  secret_id = "zendesk-subdomain"
  replication {
    auto {}
  }
}

data "google_iam_policy" "secret_zendesk_subdomain" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      google_service_account.workflow_zendesk.member,
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "zendesk_subdomain" {
  secret_id   = google_secret_manager_secret.zendesk_subdomain.secret_id
  policy_data = data.google_iam_policy.secret_zendesk_subdomain.policy_data
}

resource "google_secret_manager_secret" "zendesk_api_token" {
  secret_id = "zendesk-api-token"
  replication {
    auto {}
  }
}

data "google_iam_policy" "secret_zendesk_api_token" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      google_service_account.workflow_zendesk.member,
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "zendesk_api_token" {
  secret_id   = google_secret_manager_secret.zendesk_api_token.secret_id
  policy_data = data.google_iam_policy.secret_zendesk_api_token.policy_data
}
