-- Count the number of transitions between each page on GOV.UK as collected by GA4.
-- Only transitions between pages that exist in the content store are included.
-- https://stackoverflow.com/a/70033601/937932

CREATE TEMP TABLE page_views AS (
  SELECT
    user_pseudo_id,
    (
      SELECT
        value.int_value
      FROM
        UNNEST(event_params)
      WHERE
        key = 'ga_session_id'
    ) AS ga_session_id,
    (
      SELECT
        REGEXP_REPLACE(value.string_value, r"[?#].*", "")
      FROM
        UNNEST(event_params)
      WHERE
        key = 'page_referrer'
    ) AS from_url,
    (
      SELECT
        REGEXP_REPLACE(value.string_value, r"[?#].*", "")
      FROM
        UNNEST(event_params)
      WHERE
        key = 'page_location'
    ) AS to_url,
  FROM `ga4-analytics-352613.analytics_330577055.events_intraday_*`
  WHERE
    _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', DATE_ADD(DATE(@run_date), INTERVAL - 1 DAY))
    AND event_name = 'page_view'
);

EXPORT DATA OPTIONS(
  uri='gs://govuk-knowledge-graph-data-processed/ga4/page_to_page_transitions_*.csv.gz',
  format='CSV',
  compression='GZIP',
  overwrite=true,
  header=true
) AS

WITH

all_urls AS (
  SELECT url FROM `govuk-knowledge-graph.content.url`
  UNION ALL
  SELECT url FROM `govuk-knowledge-graph.content.parts`
)

SELECT
  COUNT(*) AS number_of_movements,
  COUNT(DISTINCT(user_pseudo_id)) AS number_of_user_pseudo_ids,
  COUNT(DISTINCT(CONCAT(user_pseudo_id, ga_session_id))) AS number_of_sessions,
  page_views.from_url,
  page_views.to_url
FROM page_views
INNER JOIN all_urls AS urls_from ON urls_from.url = page_views.from_url
INNER JOIN all_urls AS urls_to ON urls_to.url = page_views.to_url
GROUP BY
  page_views.from_url,
  page_views.to_url
HAVING
  number_of_movements > 5
  AND number_of_user_pseudo_ids > 5
  AND number_of_sessions > 5
ORDER BY
  number_of_movements DESC
