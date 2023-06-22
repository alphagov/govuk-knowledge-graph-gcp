TRUNCATE TABLE search.taxon;
INSERT INTO search.taxon
WITH
taxons AS (
  SELECT
  taxon.url AS taxon_url,
  /*
  Title is preferred to internal name because it is typically of better quality;
  internal name should be used if title is not unique / repeated.
  */
  CASE WHEN
    COUNT(taxon.title) OVER (PARTITION BY taxon.title) = 1 THEN taxon.title
    ELSE COALESCE(taxon.internal_name, taxon.title)
  END AS name,
  taxon.description,
  taxon.level,
  has_homepage.homepage_url AS url
  FROM graph.taxon
  LEFT JOIN graph.has_homepage USING (url)
),
ancestor_taxons AS (
  SELECT
    taxon_ancestors.url AS taxon_url,
    ARRAY_AGG(STRUCT(taxons.name, taxons.level, taxons.url)) AS ancestorTaxons
  FROM graph.taxon_ancestors
  INNER JOIN taxons ON taxons.taxon_url = taxon_ancestors.ancestor_url
  GROUP BY taxon_ancestors.url
),
child_taxons AS (
  SELECT
    taxon_ancestors.ancestor_url AS taxon_url,
    ARRAY_AGG(STRUCT(descendants.name, descendants.level, descendants.url)) AS childTaxons
  FROM graph.taxon_ancestors
  INNER JOIN taxons AS descendants ON descendants.taxon_url = taxon_ancestors.url
  INNER JOIN graph.taxon AS ancestor ON ancestor.url = taxon_ancestors.ancestor_url
  WHERE descendants.level = ancestor.level + 1
  GROUP BY taxon_ancestors.ancestor_url
)
SELECT
  taxons.name,
  taxons.url AS homepage,
  taxons.description,
  taxons.level,
  ancestor_taxons.ancestorTaxons,
  child_taxons.childTaxons
FROM taxons
LEFT JOIN ancestor_taxons USING (taxon_url)
LEFT JOIN child_taxons USING (taxon_url)
/* Use content.phase to filter "alpha" (deprecated) taxons */
LEFT JOIN content.phase ON phase.url = taxons.url
WHERE phase.phase != "alpha"
