-- Reuse `organisations` links as `HAS_ORGANISATION`
DELETE graph.has_organisation WHERE TRUE;
INSERT INTO graph.has_organisation
SELECT
  from_url,
  has_homepage.url  AS organisation_url
FROM content.expanded_links
INNER JOIN graph.has_homepage ON has_homepage.homepage_url = to_url
WHERE expanded_links.link_type = 'organisations'
;
