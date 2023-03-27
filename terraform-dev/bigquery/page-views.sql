-- Count the number of views of pages on GOV.UK as collected by GA4.
-- Only pages that exist in the content store are included.
TRUNCATE TABLE content.page_views;
INSERT INTO content.page_views
WITH
page_views AS (
  SELECT
  (
    SELECT REGEXP_REPLACE(value.string_value, r'[?#].*', '')
    FROM UNNEST(event_params)
    WHERE key = 'page_location'
  ) AS url,
  FROM `ga4-analytics-352613.analytics_330577055.events_*`
  WHERE
    event_name = 'page_view'
    AND _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_ADD(CURRENT_DATE(), INTERVAL - 8 DAY))
    AND _TABLE_SUFFIX <= FORMAT_DATE('%Y%m%d', DATE_ADD(CURRENT_DATE(), INTERVAL - 2 DAY))
),
all_urls AS (
  SELECT url FROM `content.url`
  UNION ALL
  SELECT url FROM `content.parts`
)
SELECT
  page_views.url,
  COUNT(*) AS number_of_views
FROM page_views
INNER JOIN all_urls ON all_urls.url = page_views.url
GROUP BY page_views.url
HAVING number_of_views > 5
ORDER BY number_of_views DESC
;
