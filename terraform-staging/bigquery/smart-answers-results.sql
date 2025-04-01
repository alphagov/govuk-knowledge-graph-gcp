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
ON T.id = S.id AND T.date_started BETWEEN min_date_started AND max_date_started
WHEN MATCHED THEN DELETE;

-- Insert new responses.
INSERT INTO smart_survey.responses
SELECT * FROM `smart_survey.SOURCE_TABLE_NAME`;

END
