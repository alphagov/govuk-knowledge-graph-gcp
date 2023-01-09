-- Reuse `ordered_child_organisations` links as `HAS_CHILD_ORGANISATION`.
DELETE graph.has_child_organisation WHERE TRUE;
INSERT INTO graph.has_child_organisation
SELECT
  from_organisation.url,
  to_organisation.url AS child_organisation_url
FROM content.expanded_links
INNER JOIN graph.has_homepage AS from_organisation ON from_organisation.homepage_url = from_url
INNER JOIN graph.has_homepage AS to_organisation ON to_organisation.homepage_url = to_url
WHERE expanded_links.link_type = 'ordered_child_organisations'
;
