CREATE TABLE `govuk-knowledge-graph.support_api.anonymous_contacts`
(
  id INT64 NOT NULL,
  type STRING NOT NULL,
  what_doing STRING,
  what_wrong STRING,
  details STRING,
  source STRING,
  page_owner STRING,
  user_agent STRING,
  referrer STRING,
  javascript_enabled BOOL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  personal_information_status STRING,
  slug STRING,
  service_satisfaction_rating INT64,
  user_specified_url STRING,
  is_actionable BOOL,
  reason_why_not_actionable STRING,
  path STRING NOT NULL,
  content_item_id INT64,
  marked_as_spam BOOL,
  reviewed BOOL
)
OPTIONS(
  friendly_name="Anonymous contacts",
  description="Contact tickets (anonymous, long-form), problem reports (collected at the bottom of a page), service feedback (rating out of 5, and what could be improved)"
);