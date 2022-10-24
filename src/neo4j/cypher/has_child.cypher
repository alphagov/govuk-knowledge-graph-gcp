// Reuse `child` links as `HAS_CHILD`.  These aren't taxons or organisations.
MATCH (a)-[:LINKS_TO {linkTargetType: 'children'}]->(b)
CREATE (a)-[:HAS_CHILD]->(b)
;
