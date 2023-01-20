-- Reuse `taxons` links as `IS_TAGGED_TO`
DELETE graph.is_tagged_to WHERE TRUE;
INSERT INTO graph.is_tagged_to
SELECT
  "https://www.gov.uk/" || from_content_id AS url,
  "https://www.gov.uk/" || to_content_id AS taxon_url
FROM content.expanded_links_content_ids
WHERE link_type = 'taxons'
;
