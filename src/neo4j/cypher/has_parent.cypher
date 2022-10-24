// Reuse `parent_taxons` links as `HAS_PARENT`.
MATCH (a:Taxon)-[:HAS_HOMEPAGE]->(b:Page)-[:LINKS_TO {linkTargetType: 'parent_taxons'}]->(c:Page)<-[:HAS_HOMEPAGE]-(d:Taxon)
CREATE (a)-[:HAS_PARENT]->(d)
;
