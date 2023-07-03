TRUNCATE TABLE content.bank_holiday_raw;
LOAD DATA INTO content.bank_holiday_raw
FROM FILES (
  format = 'JSON',
  uris = ['gs://${project_id}-data-processed/bank-holidays/bank-holidays.json']
  )
;