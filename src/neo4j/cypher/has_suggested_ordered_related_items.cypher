// Reuse `suggested_ordered_related_items` links as `HAS_SUGGESTED_ORDERED_RELATED_ITEMS`.
MATCH (p)-[:LINKS_TO {linkTargetType: 'suggested_ordered_related_items'}]->(q)
CREATE (p)-[:HAS_SUGGESTED_ORDERED_RELATED_ITEMS]->(q)
;
