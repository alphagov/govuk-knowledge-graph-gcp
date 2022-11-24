-- Derive a table of one row per line of text, per page
CREATE OR REPLACE TABLE `govuk-knowledge-graph.content.lines`AS
SELECT
  url,
  line_number + 1 AS line_number,
  line
FROM
  content.content,
  UNNEST(SPLIT(text_without_blank_lines, "\n")) AS line WITH OFFSET AS line_number
;

EXPORT DATA OPTIONS(
  uri='gs://govuk-knowledge-graph-data-processed/bigquery/lines_*.csv.gz',
  format='CSV',
  compression='GZIP',
  overwrite=true
  ) AS
SELECT * FROM content.lines
;
