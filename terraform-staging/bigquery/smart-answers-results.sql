-- Append new Smart Survey API results to the smart_survey.responses table.
-- Idempotent.

BEGIN

-- Set some variables that are required to filter by the partition
DECLARE min_date_started TIMESTAMP;
DECLARE max_date_started TIMESTAMP;
SET min_date_started = (SELECT MIN(date_started) from `smart_survey.SOURCE_TABLE_NAME`);
SET max_date_started = (SELECT MAX(date_started) from `smart_survey.SOURCE_TABLE_NAME`);

-- Delete any responses that have newer versions in the source table.
MERGE smart_survey.responses AS T
USING `smart_survey.SOURCE_TABLE_NAME` AS S
ON T.id = S.id

-- The table requires filtering by the partition, but we don't want to filter in
-- case the API changes the date_started of a survey response, which could
-- create duplicates unless we always check for the existence of every response
-- ID.
AND T.date_started >= TIMESTAMP_SECONDS(0)

WHEN MATCHED THEN DELETE;

-- Insert new responses.
INSERT INTO smart_survey.responses
SELECT * FROM `smart_survey.SOURCE_TABLE_NAME`;

END
