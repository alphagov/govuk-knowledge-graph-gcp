// Reuse `ordered_successor_organisations` links as `HAS_SUPERSEDED`.
MATCH (a)-[:LINKS_TO {linkTargetType: 'ordered_successor_organisations'}]->(b)<-[:HAS_HOMEPAGE]-(c)
CREATE (a)<-[:HAS_SUPERSEDED]-(c)
;
