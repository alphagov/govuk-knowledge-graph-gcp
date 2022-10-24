USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///first_published_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.firstPublishedAt = line.first_published_at
;
