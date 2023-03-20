-- Fail with an error message when certain conditions in the
-- `test.tables-metadata` view are met.
-- Errors will be picked up in the logs, generating an alert.
INSERT INTO `test.tables-metadata-check-results`
SELECT
  *,
  CASE
    WHEN row_count = 0 THEN ERROR(CONCAT('No data in table `', dataset_id, ".", table_id, "` last updated at ", last_modified, "."))
    WHEN last_modified < TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL - 25 HOUR) THEN ERROR(CONCAT('Old data in table `', dataset_id, ".", table_id, "` last updated at ", last_modified, "."))
    ELSE CONCAT('Table `', dataset_id, ".", table_id, "` has ", row_count, " rows, last updated at ", last_modified, ".")
  END AS result
FROM `test.tables-metadata`
