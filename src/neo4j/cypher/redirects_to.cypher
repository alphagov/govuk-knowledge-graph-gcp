USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///redirects.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.from })
MATCH (q:Page { url: line.to })
CREATE (p)-[r:REDIRECTS_TO]->(q)
;
