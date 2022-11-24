-- Cocatenate tables of content from various document types into one
CREATE OR REPLACE TABLE `govuk-knowledge-graph.content.content` AS
SELECT * FROM `govuk-knowledge-graph.content.body_content`
UNION ALL
SELECT * FROM `govuk-knowledge-graph.content.body`
UNION ALL
SELECT
  * EXCEPT(base_path, part_index)
FROM `govuk-knowledge-graph.content.parts_content`
UNION ALL
SELECT
  base_path as url,
  * EXCEPT(url, base_path, part_index)
FROM `govuk-knowledge-graph.content.parts_content`
WHERE part_index = 1
UNION ALL
SELECT * FROM `govuk-knowledge-graph.content.place_content`
UNION ALL
SELECT * FROM `govuk-knowledge-graph.content.step_by_step_content`
UNION ALL
SELECT * FROM `govuk-knowledge-graph.content.transaction_content`
-- role_content is derived from the publishing API database, which isn't updated
-- until after this query is run, because the database backup file isn't
-- available until too late in the day, so this is always a day behind the other
-- tables.
UNION ALL
SELECT * EXCEPT(govspeak) FROM `govuk-knowledge-graph.content.role_content`
;

EXPORT DATA OPTIONS(
  uri='gs://govuk-knowledge-graph-data-processed/bigquery/content_*.csv.gz',
  format='CSV',
  compression='GZIP',
  overwrite=true
  ) AS
SELECT * FROM content.content
;
