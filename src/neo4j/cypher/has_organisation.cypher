// Reuse `organisations` links as `HAS_ORGANISATION`.
MATCH (a)-[:LINKS_TO {linkTargetType: 'organisations'}]->(b)<-[:HAS_HOMEPAGE]-(c)
CREATE (a)-[:HAS_ORGANISATIONS]->(c)
;
