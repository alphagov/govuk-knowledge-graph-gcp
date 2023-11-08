-- Fail with an error message when certain conditions in the
-- `test.tables-metadata` view are met.
-- Errors will be picked up in the logs, generating an alert.
TRUNCATE TABLE `test.tables-metadata-check-results`;
INSERT INTO `test.tables-metadata-check-results`
SELECT
  *,
  CASE
    -- Raise an alert for tables that have zero rows
    WHEN row_count = 0
      -- And that aren't likely to be still being refreshed.
      -- Annoyingly, it isn't possible to TRUNCATE in the same transaction, so
      -- tables will briefly be empty until they are repopulated.
      AND last_modified < TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL - 10 MINUTE)
      -- Ignore tables that are expected to have zero rows
      AND CONCAT(dataset_id, ".", table_id) NOT IN
      (
        'content.place_abbreviations',
        'content.transaction_abbreviations',
        'content.step_by_step_abbreviations',
        'content.parts_abbreviations'
      )
      THEN ERROR(CONCAT('${alerts_error_message_no_data} `', dataset_id, ".",
          table_id, "` last updated at ", last_modified, "."))
    -- Raise an alert for tables that haven't been updated for more than a day
    WHEN last_modified < TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL - 25 HOUR) THEN ERROR(CONCAT('${alerts_error_message_old_data} `', dataset_id, ".", table_id, "` last updated at ", last_modified, "."))
    ELSE CONCAT('Table `', dataset_id, ".", table_id, "` has ", row_count, " rows, last updated at ", last_modified, ".")
  END AS result
FROM `test.tables-metadata`
;
