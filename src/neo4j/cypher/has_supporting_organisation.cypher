// Reuse `supporting_organisations` links as `HAS_SUPPORTING_ORGANISATIONS`.
MATCH (a)-[:LINKS_TO {linkTargetType: 'supporting_organisations'}]->(b)<-[:HAS_HOMEPAGE]-(c)
CREATE (a)-[:HAS_SUPPORTING_ORGANISATION]->(c)
;
