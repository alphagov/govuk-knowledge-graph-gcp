DELETE FROM search.taxon WHERE TRUE;
INSERT INTO search.taxon
WITH
taxons AS (
  SELECT
  taxon.url AS taxon_url,
  taxon.title AS name,
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

-- name: string,
-- homepage: string,
-- description: string,
-- level: number,
-- ancestorTaxons: {
--   url: string,
--   name: string,
--   level: number,
-- }[],
-- childTaxons: {
--   url: string,
--   name: string,
--   level: number
-- }[]
--
