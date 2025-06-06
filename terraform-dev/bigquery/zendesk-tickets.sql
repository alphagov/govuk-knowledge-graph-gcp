-- Append new Zendesk API tickets to the zendesk.tickets table.
-- Idempotent.

BEGIN

-- Derive a temporary table of new tickets that resembles zendesk.tickets.
CREATE TEMP TABLE _SESSION.new_tickets AS
SELECT
INT64(JSON_QUERY(result, "$.id")) AS id,
PARSE_TIMESTAMP("%Y-%m-%dT%H:%M:%SZ", JSON_VALUE(result, "$.created_at")) AS created_at,
PARSE_TIMESTAMP("%Y-%m-%dT%H:%M:%SZ", JSON_VALUE(result, "$.updated_at")) AS updated_at,
JSON_VALUE(result, '$.url') AS result_url,
  JSON_VALUE(result, '$.external_id') AS external_id,
  JSON_VALUE(result, '$.created_at') AS created_at,
  JSON_VALUE(result, '$.updated_at') AS updated_at,
  JSON_VALUE(result, '$.generated_timestamp') AS generated_timestamp,
  JSON_VALUE(result, '$.type') AS type,
  JSON_VALUE(result, '$.subject') AS subject,
  JSON_VALUE(result, '$.raw_subject') AS raw_subject,
  JSON_VALUE(result, '$.priority') AS priority,
  JSON_VALUE(result, '$.status') AS status,
  JSON_VALUE(result, '$.recipient') AS recipient,
  JSON_VALUE(result, '$.requester_id') AS requester_id,
  JSON_VALUE(result, '$.submitter_id') AS submitter_id,
  JSON_VALUE(result, '$.assignee_id') AS assignee_id,
  JSON_VALUE(result, '$.organization_id') AS organization_id,
  JSON_VALUE(result, '$.group_id') AS group_id,
  JSON_VALUE(result, '$.collaborator_ids') AS collaborator_ids,
  JSON_VALUE(result, '$.follower_ids') AS follower_ids,
  JSON_VALUE(result, '$.email_cc_ids') AS email_cc_ids,
  JSON_VALUE(result, '$.forum_topic_id') AS forum_topic_id,
  JSON_VALUE(result, '$.problem_id') AS problem_id,
  JSON_VALUE(result, '$.has_incidents') AS has_incidents,
  JSON_VALUE(result, '$.is_public') AS is_public,
  JSON_VALUE(result, '$.due_at') AS due_at,
  JSON_VALUE(result, '$.tags') AS tags,
  JSON_VALUE(result, '$.sharing_agreement_ids') AS sharing_agreement_ids,
  JSON_VALUE(result, '$.custom_status_id') AS custom_status_id,
  JSON_VALUE(result, '$.encoded_id') AS encoded_id,
  JSON_VALUE(result, '$.followup_ids') AS followup_ids,
  JSON_VALUE(result, '$.result_form_id') AS result_form_id,
  JSON_VALUE(result, '$.brand_id') AS brand_id,
  JSON_VALUE(result, '$.allow_channelback') AS allow_channelback,
  JSON_VALUE(result, '$.allow_attachments') AS allow_attachments,
  JSON_VALUE(result, '$.from_messaging_channel') AS from_messaging_channel,
  JSON_VALUE(result, '$.result_type') AS result_type,
  JSON_VALUE(result, '$.via.channel') AS via_channel,
  JSON_VALUE(result, '$.via.source.rel') AS via_source_rel,
  JSON_VALUE(result, '$.satisfaction_rating.score') AS satisfaction_rating_score,
  JSON_VALUE(result, '$.metric_set.url') AS metric_set_url,
  JSON_VALUE(result, '$.metric_set.id') AS metric_set_id,
  JSON_VALUE(result, '$.metric_set.result_id') AS metric_set_result_id,
  JSON_VALUE(result, '$.metric_set.created_at') AS metric_set_created_at,
  JSON_VALUE(result, '$.metric_set.updated_at') AS metric_set_updated_at,
  JSON_VALUE(result, '$.metric_set.group_stations') AS metric_set_group_stations,
  JSON_VALUE(result, '$.metric_set.reopens') AS metric_set_reopens,
  JSON_VALUE(result, '$.metric_set.replies') AS metric_set_replies,
  JSON_VALUE(result, '$.metric_set.assignee_updated_at') AS metric_set_assignee_updated_at,
  JSON_VALUE(result, '$.metric_set.requester_updated_at') AS metric_set_requester_updated_at,
  JSON_VALUE(result, '$.metric_set.status_updated_at') AS metric_set_status_updated_at,
  JSON_VALUE(result, '$.metric_set.initially_assigned_at') AS metric_set_initially_assigned_at,
  JSON_VALUE(result, '$.metric_set.assigned_at') AS metric_set_assigned_at,
  JSON_VALUE(result, '$.metric_set.solved_at') AS metric_set_solved_at,
  JSON_VALUE(result, '$.metric_set.latest_comment_added_at') AS metric_set_latest_comment_added_at,
  JSON_VALUE(result, '$.metric_set.reply_time_in_minutes.calendar') AS metric_set_reply_time_in_minutes_calendar,
  JSON_VALUE(result, '$.metric_set.reply_time_in_minutes.business') AS metric_set_reply_time_in_minutes_business,
  JSON_VALUE(result, '$.metric_set.first_resolution_time_in_minutes.calendar') AS metric_set_first_resolution_time_in_minutes_calendar,
  JSON_VALUE(result, '$.metric_set.first_resolution_time_in_minutes.business') AS metric_set_first_resolution_time_in_minutes_business,
  JSON_VALUE(result, '$.metric_set.full_resolution_time_in_minutes.calendar') AS metric_set_full_resolution_time_in_minutes_calendar,
  JSON_VALUE(result, '$.metric_set.full_resolution_time_in_minutes.business') AS metric_set_full_resolution_time_in_minutes_business,
  JSON_VALUE(result, '$.metric_set.agent_wait_time_in_minutes.calendar') AS metric_set_agent_wait_time_in_minutes_calendar,
  JSON_VALUE(result, '$.metric_set.agent_wait_time_in_minutes.business') AS metric_set_agent_wait_time_in_minutes_business,
  JSON_VALUE(result, '$.metric_set.requester_wait_time_in_minutes.calendar') AS metric_set_requester_wait_time_in_minutes_calendar,
  JSON_VALUE(result, '$.metric_set.requester_wait_time_in_minutes.business') AS metric_set_requester_wait_time_in_minutes_business,
  JSON_VALUE(result, '$.metric_set.on_hold_time_in_minutes.calendar') AS metric_set_on_hold_time_in_minutes_calendar,
  JSON_VALUE(result, '$.metric_set.on_hold_time_in_minutes.business') AS metric_set_on_hold_time_in_minutes_business,
  JSON_VALUE(result, '$.via.source.from.address') AS via_source_from_address,
  JSON_VALUE(result, '$.via.source.from.name') AS via_source_from_name,
  JSON_VALUE(result, '$.via.source.to.name') AS via_source_to_name,
  JSON_VALUE(result, '$.via.source.to.address') AS via_source_to_address,
result AS ticket
FROM `zendesk.SOURCE_TABLE_NAME`
CROSS JOIN UNNEST(results) AS result;

-- Delete any tickets that have newer versions in the source table.
MERGE zendesk.tickets AS T
USING _SESSION.new_tickets AS S
ON T.id = S.id

-- The table requires filtering by the partition, but we don't want to filter in
-- case the API changes the created_at of a ticket, which could create
-- duplicates unless we always check for the existence of every response ID.
AND T.created_at >= TIMESTAMP_SECONDS(0)

WHEN MATCHED THEN DELETE;

-- Insert new tickets.
INSERT INTO zendesk.tickets
SELECT * FROM _SESSION.new_tickets;

DROP TABLE _SESSION.new_tickets;

END
