// Reuse `primary_publishing_organisation` links as `HAS_PRIMARY_PUBLISHING_ORGANISATION`.
MATCH (a)-[:LINKS_TO {linkTargetType: 'primary_publishing_organisation'}]->(b)<-[:HAS_HOMEPAGE]-(c)
CREATE (a)-[:HAS_PRIMARY_PUBLISHING_ORGANISATION]->(c)
;
