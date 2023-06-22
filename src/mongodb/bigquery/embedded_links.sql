-- Concatenate tables of embedded links from various document types into one
TRUNCATE TABLE `content.embedded_links`;
INSERT INTO `content.embedded_links`
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
  uri='gs://$PROJECT_ID-data-processed/bigquery/embedded_links_*.csv.gz',
  format='CSV',
  compression='GZIP',
  overwrite=true
  ) AS
SELECT * FROM content.embedded_links;
