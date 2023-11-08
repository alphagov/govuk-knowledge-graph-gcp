TRUNCATE TABLE graph.has_successor;
INSERT INTO graph.has_successor
SELECT
  "https://www.gov.uk/" || from_content_id AS url,
  "https://www.gov.uk/" || to_content_id AS successor_url
FROM content.expanded_links_content_ids
WHERE link_type = 'ordered_successor_organisations'
;
