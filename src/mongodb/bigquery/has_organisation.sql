-- Reuse `organisations` links as `HAS_ORGANISATION`
TRUNCATE TABLE graph.has_organisation;
INSERT INTO graph.has_organisation
SELECT
  "https://www.gov.uk/" || from_content_id AS url,
  "https://www.gov.uk/" || to_content_id AS organisation_url
FROM content.expanded_links_content_ids
WHERE link_type = 'organisations'
;
