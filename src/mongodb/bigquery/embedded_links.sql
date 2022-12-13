-- Cocatenate tables of embedded links from various document types into one
DECLARE PROJECT_ID STRING DEFAULT 'govuk-knowledge-graph-staging';
DECLARE URI STRING;
SET URI=FORMAT('gs://%s-data-processed/bigquery/embedded_links_*.csv.gz', PROJECT_ID);

CREATE OR REPLACE TABLE `content.embedded_links`AS
SELECT * FROM `content.body_embedded_links`
UNION ALL
SELECT * FROM `content.body_content_embedded_links`
UNION ALL
SELECT
  * EXCEPT(base_path, part_index)
FROM `content.parts_embedded_links`
UNION ALL
SELECT
  count,
  base_path as url,
  * EXCEPT(count, url, base_path, part_index)
FROM `content.parts_embedded_links`
WHERE part_index = 1
UNION ALL
SELECT * FROM `content.place_embedded_links`
UNION ALL
SELECT * FROM `content.step_by_step_embedded_links`
UNION ALL
SELECT * FROM `content.step_by_step_embedded_links`
UNION ALL
SELECT * FROM `content.transaction_embedded_links`
-- role_content is derived from the publishing API database, which isn't updated
-- until after this query is run, because the database backup file isn't
-- available until too late in the day, so this is always a day behind the other
-- tables.
UNION ALL
SELECT * FROM `content.role_embedded_links`
;

EXPORT DATA OPTIONS(
  uri=(URI),
  format='CSV',
  compression='GZIP',
  overwrite=true
  ) AS
SELECT * FROM content.embedded_links
;

CREATE OR REPLACE TABLE `content.embedded_links`AS
SELECT * FROM `content.body_embedded_links`
UNION ALL
SELECT * FROM `content.body_content_embedded_links`
UNION ALL
SELECT
  * EXCEPT(base_path, part_index)
FROM `content.parts_embedded_links`
UNION ALL
SELECT
  count,
  base_path as url,
  * EXCEPT(count, url, base_path, part_index)
FROM `content.parts_embedded_links`
WHERE part_index = 1
UNION ALL
SELECT * FROM `content.place_embedded_links`
UNION ALL
SELECT * FROM `content.step_by_step_embedded_links`
UNION ALL
SELECT * FROM `content.step_by_step_embedded_links`
UNION ALL
SELECT * FROM `content.transaction_embedded_links`
-- role_content is derived from the publishing API database, which isn't updated
-- until after this query is run, because the database backup file isn't
-- available until too late in the day, so this is always a day behind the other
-- tables.
UNION ALL
SELECT * FROM `content.role_embedded_links`
;

EXPORT DATA OPTIONS(
  uri=(URI),
  format='CSV',
  compression='GZIP',
  overwrite=true
  ) AS
SELECT * FROM content.embedded_links;
