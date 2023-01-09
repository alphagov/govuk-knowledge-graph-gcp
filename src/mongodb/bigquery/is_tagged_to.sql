-- Reuse `taxons` links as `IS_TAGGED_TO`
DELETE graph.is_tagged_to WHERE TRUE;
INSERT INTO graph.is_tagged_to
SELECT
  from_url AS url,
  has_homepage.url AS taxon_url
FROM content.expanded_links
INNER JOIN graph.has_homepage ON has_homepage.homepage_url = to_url
WHERE expanded_links.link_type = 'taxons'
;
