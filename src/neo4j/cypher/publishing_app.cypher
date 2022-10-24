USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///publishing_app.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.publishingApp = line.publishing_app
;
