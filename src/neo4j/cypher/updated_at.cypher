USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///updated_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.updatedAt = line.updated_at
;
