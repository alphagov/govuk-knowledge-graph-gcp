-- Reuse `primary_publishing_organisation` links as `HAS_PRIMARY_PUBLISHING_ORGANISATION`
DELETE graph.has_primary_publishing_organisation WHERE TRUE;
INSERT INTO graph.has_primary_publishing_organisation
SELECT
  "https://www.gov.uk/" || from_content_id AS url,
  "https://www.gov.uk/" || to_content_id AS primary_publishing_organisation_url
FROM content.expanded_links_content_ids
WHERE link_type = 'primary_publishing_organisation'
;
