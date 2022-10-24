USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///body.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;
