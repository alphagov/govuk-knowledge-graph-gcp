-- Derive a table, one row per taxon, per ancestor of that taxon.
DELETE graph.taxon_ancestors WHERE TRUE;
INSERT INTO graph.taxon_ancestors
WITH RECURSIVE
  -- We could use the name 'taxon' instead of 'T1', but because there is already
  -- a table called 'taxon', BigQuery confuses them.
  T1 AS (
    (
      SELECT
        url,
        parent_url,
      FROM graph.has_parent
    )
    UNION ALL
    (
      SELECT
        T1.url,
        has_parent.parent_url,
      FROM T1
      INNER JOIN graph.has_parent ON has_parent.url = T1.parent_url
    )
  )
SELECT DISTINCT
  T1.url,
  taxon_title.title,
  T1.parent_url AS ancestor_url,
  ancestor_title.title AS ancestor_title
FROM T1
INNER JOIN graph.taxon AS taxon_title ON taxon_title.url = T1.url
INNER JOIN graph.taxon AS ancestor_title ON ancestor_title.url = T1.parent_url
ORDER BY T1.url, ancestor_url
;
