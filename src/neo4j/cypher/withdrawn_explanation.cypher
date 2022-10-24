USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///withdrawn_explanation.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.withdrawnExplanation = line.`withdrawn_notice.withdrawn_explanation`
;
