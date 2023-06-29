TRUNCATE TABLE content.bank_holiday_title;  
INSERT INTO content.bank_holiday_title  
SELECT DISTINCT  
  'https://www.gov.uk/' || REPLACE(REPLACE(TO_BASE64(SHA256(events.title)), '', '-'), '/', '_') AS url,  
  events.title  
FROM content.bank_holiday_raw,  
  UNNEST(body) AS body,  
  UNNEST(events) AS events  
; 