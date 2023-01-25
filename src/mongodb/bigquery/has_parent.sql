-- Reuse `parent_taxons` links as `HAS_PARENT`.
DELETE graph.has_parent WHERE TRUE;
INSERT INTO graph.has_parent
SELECT
  "https://www.gov.uk/" || from_content_id AS url,
  "https://www.gov.uk/" || to_content_id AS parent_url
FROM content.expanded_links_content_ids
WHERE link_type IN ('parent_taxons', 'root_taxon')
;
