// Reuse `taxons` links as `IS_TAGGED_TO`.
MATCH (a)-[:LINKS_TO {linkTargetType: 'taxons'}]->(b)<-[:HAS_HOMEPAGE]-(c)
CREATE (a)-[:IS_TAGGED_TO]->(c)
;
