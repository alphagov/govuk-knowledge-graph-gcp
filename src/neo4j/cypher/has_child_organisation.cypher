// Reuse `ordered_child_organisations` links as `HAS_CHILD_ORGANISATION`.
MATCH (a:Organisation)-[:HAS_HOMEPAGE]->(b:Page)-[:LINKS_TO {linkTargetType: 'ordered_child_organisations'}]->(c:Page)<-[:HAS_HOMEPAGE]-(d:Organisation)
CREATE (a)-[:HAS_CHILD_ORGANISATION]->(d)
;
