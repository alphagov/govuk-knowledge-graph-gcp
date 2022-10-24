// Create LINKS_TO relationship (expanded links)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///expanded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.from_url })
MATCH (q:Page { url: line.to_url })
CREATE (p)-[:LINKS_TO { linkTargetType: line.link_type, linkIndex: line.link_index }]->(q)
;
