USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///description.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.description = line.description
;
