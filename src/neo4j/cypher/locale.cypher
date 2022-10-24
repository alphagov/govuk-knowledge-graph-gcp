USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///locale.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.locale = line.locale
;
