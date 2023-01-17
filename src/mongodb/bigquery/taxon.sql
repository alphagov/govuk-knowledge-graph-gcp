DELETE graph.taxon WHERE TRUE;
INSERT INTO graph.taxon
SELECT
  taxon_levels.url,
  page.title,
  page.content_id,
  taxon_levels.level
FROM content.taxon_levels
INNER JOIN graph.page AS page ON taxon_levels.homepage_url = page.url
;
