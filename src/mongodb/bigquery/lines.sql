-- Derive a table of one row per line of text, per page
DECLARE PROJECT_ID STRING DEFAULT 'govuk-knowledge-graph-dev';
DECLARE URI STRING;
SET URI=FORMAT('gs://%s-data-processed/bigquery/lines_*.csv.gz', PROJECT_ID);

DELETE content.lines WHERE TRUE;
INSERT INTO content.lines
SELECT
  url,
  line_number + 1 AS line_number,
  line
FROM
  content.content,
  UNNEST(SPLIT(text_without_blank_lines, "\n")) AS line WITH OFFSET AS line_number
;

EXPORT DATA OPTIONS(
  uri=(URI),
  format='CSV',
  compression='GZIP',
  overwrite=true
  ) AS
SELECT * FROM content.lines
;
