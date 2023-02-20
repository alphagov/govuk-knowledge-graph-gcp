DELETE FROM search.bank_holiday WHERE TRUE;
INSERT INTO search.bank_holiday
SELECT
  bank_holiday_title.title AS name,
  -- Theoretically, a bank holiday could occur on different dates in different
  -- divisions, but govsearch displays two independents lists, one of divisions,
  -- and another of dates.  It doesn't show a direct association between dates
  -- and divisions.
  ARRAY_AGG(DISTINCT division) AS divisions,
  ARRAY_AGG(DISTINCT date) AS dates
FROM content.bank_holiday_url
LEFT JOIN content.bank_holiday_title USING (url)
LEFT JOIN content.bank_holiday_occurrence USING (url)
GROUP BY
  bank_holiday_title.title,
  bank_holiday_url.url
