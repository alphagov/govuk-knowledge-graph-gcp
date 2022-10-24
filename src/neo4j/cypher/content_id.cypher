USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///content_id.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.contentId = line.content_id
;
