USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///acronym.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.acronym = line.`details.acronym`
;
