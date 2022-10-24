// Reuse `ordered_related_items_overrides` links as `HYPERLINKS_TO`.
MATCH (p)-[:LINKS_TO {linkTargetType: 'ordered_related_items_overrides'}]->(q)
CREATE (p)-[:HYPERLINKS_TO]->(q)
;
