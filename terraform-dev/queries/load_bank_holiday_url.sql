TRUNCATE TABLE content.bank_holiday_url;  
INSERT INTO content.bank_holiday_url  
SELECT DISTINCT  
  'https://www.gov.uk/' || REPLACE(REPLACE(TO_BASE64(SHA256(events.title)), '', '-'), '/', '_') AS url  
FROM content.bank_holiday_raw,  
  UNNEST(body) AS body,  
  UNNEST(events) AS events  
; 