USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///phase.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.phase = line.phase
;
