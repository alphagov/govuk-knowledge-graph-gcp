-- Concatenate tables of content from various document types into one
CREATE OR REPLACE TABLE `content.content` AS
SELECT * FROM `content.body_content`
UNION ALL
SELECT * FROM `content.body`
UNION ALL
SELECT
  * EXCEPT(base_path, part_index)
FROM `content.parts_content`
UNION ALL
SELECT
  base_path as url,
  * EXCEPT(url, base_path, part_index)
FROM `content.parts_content`
WHERE part_index = 1
UNION ALL
SELECT * FROM `content.place_content`
UNION ALL
SELECT * FROM `content.step_by_step_content`
UNION ALL
SELECT * FROM `content.transaction_content`
-- role_content is derived from the publishing API database, which isn't updated
-- until after this query is run, because the database backup file isn't
-- available until too late in the day, so this is always a day behind the other
-- tables.
UNION ALL
SELECT * EXCEPT(govspeak) FROM `content.role_content`
;

EXPORT DATA OPTIONS(
  uri='gs://$PROJECT_ID-data-processed/bigquery/content_*.csv.gz',
  format='CSV',
  compression='GZIP',
  overwrite=true
  ) AS
SELECT * FROM content.content
;
