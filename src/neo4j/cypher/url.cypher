USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///url.csv' AS line
FIELDTERMINATOR ','
CREATE (p:Page { url: line.url })
;
