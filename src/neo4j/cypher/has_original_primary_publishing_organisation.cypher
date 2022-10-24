// Reuse `original_primary_publishing_organisation` links as `HAS_ORIGINAL_PRIMARY_PUBLISHING_ORGANISATION`.
MATCH (a)-[:LINKS_TO {linkTargetType: 'original_primary_publishing_organisation'}]->(b)<-[:HAS_HOMEPAGE]-(c)
CREATE (a)-[:HAS_ORIGINAL_PRIMARY_PUBLISHING_ORGANISATION]->(c)
;
