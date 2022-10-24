USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///analytics_identifier.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.analyticsIdentifier = line.analytics_identifier
;
