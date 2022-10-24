// Reuse `ordered_related_items` links as `HYPERLINKS_TO`.
MATCH (p)-[:LINKS_TO {linkTargetType: 'ordered_related_items'}]->(q)
CREATE (p)-[:HYPERLINKS_TO]->(q)
;
