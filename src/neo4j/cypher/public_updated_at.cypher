USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///public_updated_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.publicUpdatedAt = line.public_updated_at
;
