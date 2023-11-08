-- Derive a table, one row per taxon, per ancestor of that taxon.
TRUNCATE TABLE graph.taxon_ancestors;
INSERT INTO graph.taxon_ancestors
WITH RECURSIVE
  -- We could use the name 'taxon' instead of 'T1', but because there is already
  -- a table called 'taxon', BigQuery confuses them.
  T1 AS (
    (
      -- The base case is that a taxon is one of its own ancestors. This makes
      -- it simple to query for pages that are tagged to a taxon or its
      -- ancestors.
      SELECT
        url,
        url AS parent_url,
      FROM content.taxon_levels
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
