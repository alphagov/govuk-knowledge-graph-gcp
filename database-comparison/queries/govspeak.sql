-- Does the publishing database have only govspeak or also html?
\copy (
select details
from editions
where base_path = '/government/ministers/prime-minister'
order by updated_at desc
limit 1
) to 'data/govspeak-publishing.json'
;

-- Does the content_postgres database have only govspeak or also html?
\copy (
select details::json
from content_items
where base_path = '/government/ministers/prime-minister'
order by updated_at desc
limit 1
) to 'data/govspeak-content-postgres.json'
;

psql \
  --tuples-only \
  --command="SELECT row_to_json(content_items) FROM content_items where base_path = '/government/ministers/prime-minister' order by updated_at desc limit 1;" \
  > data/govspeak-content-postgres.json

-- Do any documents in the Publishing database have HTML?
-- This query only looks in a particular place.
SELECT schema_name, count(*)
FROM editions_latest
WHERE details #> '{body}' @> '[{"content_type": "text/html"}]'::jsonb
GROUP BY schema_name
;
--          schema_name         | count
-- -----------------------------+-------
--  financial_release           |     1
--  financial_releases_campaign |     1
--  help_page                   |     1
--  manual                      |   224
--  manual_section              |  3978
--  person                      |    63
--  role                        |     6
--  specialist_document         |   353

SELECT schema_name, count(*)
FROM editions_latest
WHERE details #> '{body}' @> '[{"content_type": "text/govspeak"}]'::jsonb
GROUP BY schema_name
;
--          schema_name         | count
-- -----------------------------+--------
--  answer                      |    938
--  financial_release           |      1
--  financial_releases_campaign |      1
--  help_page                   |     13
--  manual                      |    224
--  manual_section              |   3978
--  person                      |   5495
--  role                        |    802
--  simple_smart_answer         |     45
--  specialist_document         | 186821

-- Lots of documents have HTML body
SELECT schema_name, LEFT(details->>'body', 1) AS first_character, count(*)
FROM editions_latest
WHERE jsonb_typeof(details->'body') = 'string'
GROUP BY schema_name, first_character
;
--              schema_name              | first_character | count
-- --------------------------------------+-----------------+--------
--  calendar                             |                 |      2
--  calendar                             | I               |      1
--  call_for_evidence                    | <               |    458
--  case_study                           | <               |   2750
--  consultation                         | <               |   6561
--  corporate_information_page           | <               |   2781
--  detailed_guide                       | <               |  15183
--  document_collection                  | <               |   6993
--  fatality_notice                      | <               |    537
--  financial_releases_geoblocker        | <               |      5
--  financial_releases_success           | <               |      1
--  historic_appointment                 | <               |     54
--  history                              |                +|      6
--                                       |                 |
--  hmrc_manual_section                  |                +|   9619
--                                       |                 |
--  hmrc_manual_section                  | <               |  72509
--  html_publication                     |                 |    733
--  html_publication                     | <               |  84342
--  manual                               | <               |      1
--  manual_section                       | <               |     20
--  ministers_index                      | R               |      1
--  news_article                         |                +|    655
--                                       |                 |
--  news_article                         | <               | 120868
--  organisation                         | <               |   1202
--  placeholder_specialist_document      | <               |      2
--  publication                          | <               | 215164
--  service_manual_guide                 |                +|      6
--                                       |                 |
--  service_manual_guide                 | <               |    229
--  service_manual_service_standard      | <               |      1
--  specialist_document                  | <               |      4
--  speech                               | <               |  15388
--  statistical_data_set                 | <               |   1385
--  step_by_step_nav                     | <               |     33
--  take_part                            | <               |     17
--  topical_event                        | <               |    128
--  topical_event_about_page             | <               |     58
--  working_group                        |                 |     71
--  working_group                        | <               |    908
--  world_location_news_article          | <               |    258
--  worldwide_corporate_information_page | <               |    445
--  worldwide_organisation               |                 |      3
--  worldwide_organisation               | <               |    555

-- Whereas, in the postgres content store
SELECT schema_name, count(*)
FROM content_items
WHERE details #> '{body}' @> '[{"content_type": "text/html"}]'::jsonb
GROUP BY schema_name
;
--      schema_name     | count
-- ---------------------+--------
--  answer              |    836
--  help_page           |     11
--  manual              |    160
--  manual_section      |   2866
--  person              |   5253
--  role                |    759
--  simple_smart_answer |     39
--  specialist_document | 184201

SELECT schema_name, count(*)
FROM content_items
WHERE details #> '{body}' @> '[{"content_type": "text/govspeak"}]'::jsonb
GROUP BY schema_name
;
--      schema_name     | count
-- ---------------------+--------
--  answer              |    836
--  help_page           |     10
--  manual              |    160
--  manual_section      |   2866
--  person              |   5253
--  role                |    759
--  simple_smart_answer |     39
--  specialist_document | 184201

SELECT base_path, details #> '{body}' AS body, details #> '{body, content}' AS body_content
FROM content_items
WHERE schema_name = 'answer'
LIMIT 1
;

SELECT base_path, details
FROM content_items
WHERE schema_name = 'history'
LIMIT 1
;

SELECT base_path, details
FROM editions_latest
WHERE schema_name = 'history'
LIMIT 1
;

SELECT base_path, details
FROM content_items
WHERE schema_name = 'news_article'
LIMIT 1
;

SELECT base_path, details
FROM editions_latest
WHERE schema_name = 'news_article'
LIMIT 1
;
