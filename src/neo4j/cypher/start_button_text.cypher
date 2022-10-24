// Transaction start button text
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///start_button_text.csv' AS line
FIELDTERMINATOR ','
MATCH (:Page { url: line.url })-[r:TRANSACTION_STARTS_AT]->()
SET r.linkText = line.`details.start_button_text`
;
