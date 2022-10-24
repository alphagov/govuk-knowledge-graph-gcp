// Reuse `ordered_parent_organisations` links as `HAS_PARENT_ORGANISATION`.
MATCH (a:Organisation)-[:HAS_HOMEPAGE]->(b:Page)-[:LINKS_TO {linkTargetType: 'ordered_parent_organisations'}]->(c:Page)<-[:HAS_HOMEPAGE]-(d:Organisation)
CREATE (a)-[:HAS_PARENT_ORGANISATION]->(d)
;
