-- Concatenate tables of embedded links from various document types into one
CREATE OR REPLACE TABLE `content.abbreviations`AS
SELECT * FROM `content.body_abbreviations`
UNION ALL
SELECT * FROM `content.body_content_abbreviations`
UNION ALL
SELECT
  * EXCEPT(base_path, part_index)
FROM `content.parts_abbreviations`
UNION ALL
SELECT
  count,
  base_path as url,
  * EXCEPT(count, url, base_path, part_index)
FROM `content.parts_abbreviations`
WHERE part_index = 1
UNION ALL
SELECT * FROM `content.place_abbreviations`
UNION ALL
SELECT * FROM `content.step_by_step_abbreviations`
UNION ALL
SELECT * FROM `content.step_by_step_abbreviations`
UNION ALL
SELECT * FROM `content.transaction_abbreviations`
-- role_content is derived from the publishing API database, which isn't updated
-- until after this query is run, because the database backup file isn't
-- available until too late in the day, so this is always a day behind the other
-- tables.
UNION ALL
SELECT * FROM `content.role_abbreviations`
;

EXPORT DATA OPTIONS(
  uri='gs://$PROJECT_ID-data-processed/bigquery/abbreviations_*.csv.gz',
  format='CSV',
  compression='GZIP',
  overwrite=true
  ) AS
SELECT * FROM content.abbreviations
;

CREATE OR REPLACE TABLE `content.abbreviations`AS
SELECT * FROM `content.body_abbreviations`
UNION ALL
SELECT * FROM `content.body_content_abbreviations`
UNION ALL
SELECT
  * EXCEPT(base_path, part_index)
FROM `content.parts_abbreviations`
UNION ALL
SELECT
  count,
  base_path as url,
  * EXCEPT(count, url, base_path, part_index)
FROM `content.parts_abbreviations`
WHERE part_index = 1
UNION ALL
SELECT * FROM `content.place_abbreviations`
UNION ALL
SELECT * FROM `content.step_by_step_abbreviations`
UNION ALL
SELECT * FROM `content.step_by_step_abbreviations`
UNION ALL
SELECT * FROM `content.transaction_abbreviations`
-- role_content is derived from the publishing API database, which isn't updated
-- until after this query is run, because the database backup file isn't
-- available until too late in the day, so this is always a day behind the other
-- tables.
UNION ALL
SELECT * FROM `content.role_abbreviations`
;

EXPORT DATA OPTIONS(
  uri='gs://$PROJECT_ID-data-processed/bigquery/abbreviations_*.csv.gz',
  format='CSV',
  compression='GZIP',
  overwrite=true
  ) AS
SELECT * FROM content.abbreviations;
