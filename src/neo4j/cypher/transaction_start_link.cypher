// Transaction start button link (must come before button text)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///transaction_start_link.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
MERGE (q:Page { url: line.link_url_bare })
CREATE (p)-[:TRANSACTION_STARTS_AT { linkUrl: line.link_url_bare }]->(q)
;
