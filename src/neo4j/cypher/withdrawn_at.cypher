USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///withdrawn_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.withdrawnAt = line.`withdrawn_notice.withdrawn_at`
;
