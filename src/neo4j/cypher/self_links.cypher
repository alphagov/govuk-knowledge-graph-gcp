// Remove self-links, which are pages that are translations of themselves
MATCH (n)-[r:LINKS_TO {linkTargetType: 'available_translations'}]->(n)
DELETE r
;
