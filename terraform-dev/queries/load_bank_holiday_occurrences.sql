TRUNCATE TABLE content.bank_holiday_occurrence; 
INSERT INTO content.bank_holiday_occurrence 
SELECT 
  'https://www.gov.uk/' || REPLACE(REPLACE(TO_BASE64(SHA256(events.title)), '+', '-'), '/', '_') AS url, 
  events.date, 
  body.division AS division, 
  events.bunting, 
  events.notes 
FROM content.bank_holiday_raw, 
UNNEST(body) AS body, 
UNNEST(events) AS events 
;