-- Reuse `primary_publishing_organisation` links as `HAS_PRIMARY_PUBLISHING_ORGANISATION`
DELETE graph.has_primary_publishing_organisation WHERE TRUE;
INSERT INTO graph.has_primary_publishing_organisation
SELECT
  from_url,
  has_homepage.url  AS primary_publishing_organisation_url
FROM content.expanded_links
INNER JOIN graph.has_homepage ON has_homepage.homepage_url = to_url
WHERE expanded_links.link_type = 'primary_publishing_organisation'
;
