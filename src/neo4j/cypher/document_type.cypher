USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///document_type.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.documentType = line.document_type
;
