-- Maintains a table `public.content` of
-- * one record per document if the document has a single part
-- * one record per part of multipart documents, whare the ones with schema_name
--   IN ('guide', 'travel_advice')
--
-- 1. Fetch new editions since the last batch update from
--    public.publishing_api_editions_new_current.
-- 2. Extract markup from those editions according to their schema.
-- 3. Where HTML is null, render the GovSpeak to HTML.
-- 4. Extract plain text and various HTML tags from the HTML.
-- 5. Delete outdated editions from public.content.
-- 6. Insert new editions into public.content.

BEGIN

-- Extract the govspeak and/or html versions of content from a JSON array
--
-- Example input:
-- [
--  {"content":"# Govspeak Content","content_type":"text/govspeak"},
--  {"content":"<h1>HTML Content</h1>","content_type":"text/html"}
-- ]
--
-- Output: STRUCT(govspeak, html)
CREATE TEMP FUNCTION markup_from_json_array(array_of_json JSON) AS ((
    WITH keyvalues AS (
      SELECT
        STRING(JSON_QUERY(item, '$.content')) AS content,
        STRING(JSON_QUERY(item, '$.content_type')) AS content_type
      FROM UNNEST(JSON_QUERY_ARRAY(array_of_json)) AS item
    )
    SELECT (SELECT AS STRUCT govspeak AS govspeak, html AS html)
    FROM keyvalues
    PIVOT(
      ANY_VALUE(content)
      FOR content_type IN ('text/govspeak' as govspeak, 'text/html' as html)
    )
));

-- https://stackoverflow.com/a/55778635
CREATE TEMP FUNCTION dedup(val ANY TYPE) AS ((
  SELECT ARRAY_AGG(t)
  FROM (SELECT DISTINCT * FROM UNNEST(val) v) t
));

TRUNCATE TABLE public.content_new;
INSERT INTO public.content_new
-- schema_map ought to be a table, but it would take a lot of configuration.  If
-- we used DBT or SQLMesh then it would be easier, as a seed, but those tools
-- also require a lot of configuration.
WITH schema_map AS (
  SELECT 'calendar' AS schema_name, 'body' AS govspeak_location
  UNION ALL SELECT 'call_for_evidence', 'body'
  UNION ALL SELECT 'case_study', 'body'
  UNION ALL SELECT 'consultation', 'body'
  UNION ALL SELECT 'corporate_information_page', 'body'
  UNION ALL SELECT 'detailed_guide', 'body'
  UNION ALL SELECT 'document_collection', 'body'
  UNION ALL SELECT 'fatality_notice', 'body'
  UNION ALL SELECT 'historic_appointment', 'body'
  UNION ALL SELECT 'history', 'body'
  UNION ALL SELECT 'hmrc_manual_section', 'body'
  UNION ALL SELECT 'html_publication', 'body'
  UNION ALL SELECT 'news_article', 'body'
  UNION ALL SELECT 'organisation', 'body'
  UNION ALL SELECT 'publication', 'body'
  UNION ALL SELECT 'service_manual_guide', 'body'
  UNION ALL SELECT 'service_manual_service_standard', 'body'
  UNION ALL SELECT 'speech', 'body'
  UNION ALL SELECT 'step_by_step_nav', 'body'
  UNION ALL SELECT 'statistical_data_set', 'body'
  UNION ALL SELECT 'take_part', 'body'
  UNION ALL SELECT 'topical_event', 'body'
  UNION ALL SELECT 'topical_event_about_page', 'body'
  UNION ALL SELECT 'working_group', 'body'
  UNION ALL SELECT 'worldwide_corporate_information_page', 'body'
  UNION ALL SELECT 'worldwide_organisation', 'body'

  UNION ALL SELECT 'answer', 'body_content'
  UNION ALL SELECT 'help_page', 'body_content'
  UNION ALL SELECT 'manual', 'body_content'
  UNION ALL SELECT 'manual_section', 'body_content'
  UNION ALL SELECT 'person', 'body_content'
  UNION ALL SELECT 'role', 'body_content'
  UNION ALL SELECT 'simple_smart_answer', 'body_content'
  UNION ALL SELECT 'specialist_document', 'body_content'

  UNION ALL SELECT 'guide', 'part'
  UNION ALL SELECT 'travel_advice', 'part'

  UNION ALL SELECT 'place', 'general'
  UNION ALL SELECT 'licence', 'general'
  UNION ALL SELECT 'local_transaction', 'general'
  UNION ALL SELECT 'transaction', 'general'
  UNION ALL SELECT 'statistics_announcement', 'general'
  UNION ALL SELECT 'smart_answer', 'general'
),

-- HTML content of document types that have it in the "body" field.
body AS (
  SELECT
    editions.id AS edition_id,
    editions.document_id,
    editions.schema_name,
    editions.base_path,
    editions.title,
    FALSE AS is_part,
    CAST(NULL AS INT64) AS part_index,
    CAST(NULL AS STRING) AS part_slug,
    CAST(NULL AS STRING) AS part_title,
    CAST(NULL AS STRING) AS govspeak,
    STRING(JSON_QUERY(editions.details, '$.body')) AS html,
  FROM public.publishing_api_editions_new_current AS editions
  INNER JOIN schema_map USING (schema_name)
  WHERE schema_map.govspeak_location = 'body'
  AND JSON_TYPE(JSON_QUERY(details, '$.body')) = 'string'
),

-- govspeak and HTML content of document types that have it in the "body.content[]" array.
body_content_content AS (
  SELECT
    editions.id AS edition_id,
    editions.document_id,
    editions.schema_name,
    editions.base_path,
    editions.title,
    FALSE AS is_part,
    CAST(NULL AS INT64) AS part_index,
    CAST(NULL AS STRING) AS part_slug,
    CAST(NULL AS STRING) AS part_title,
    markup_from_json_array(JSON_QUERY(editions.details, '$.body')) AS content
  FROM public.publishing_api_editions_new_current AS editions
  INNER JOIN schema_map USING (schema_name)
  WHERE schema_map.govspeak_location = 'body_content'
  AND JSON_TYPE(JSON_QUERY(editions.details, '$.body')) = 'array'
),
body_content AS (
  SELECT
    * EXCEPT (content),
    content.govspeak AS govspeak,
    content.html AS html
  FROM body_content_content
),

general_content AS (
  SELECT
    editions.id AS edition_id,
    editions.document_id,
    editions.schema_name,
    editions.base_path,
    editions.title,
    FALSE AS is_part,
    CAST(NULL AS INT64) AS part_index,
    CAST(NULL AS STRING) AS part_slug,
    CAST(NULL AS STRING) AS part_title,
    markup_from_json_array(JSON_QUERY(editions.details, '$.introduction')) AS introduction,
    markup_from_json_array(JSON_QUERY(editions.details, '$.information')) AS information,
    markup_from_json_array(JSON_QUERY(editions.details, '$.need_to_know')) AS need_to_know,
    markup_from_json_array(JSON_QUERY(editions.details, '$.introductory_paragraph')) AS introductory_paragraph,
    markup_from_json_array(JSON_QUERY(editions.details, '$.licence_overview')) AS licence_overview,
    markup_from_json_array(JSON_QUERY(editions.details, '$.start_button_text')) AS start_button_text,
    markup_from_json_array(JSON_QUERY(editions.details, '$.will_continue_on')) AS will_continue_on,
    markup_from_json_array(JSON_QUERY(editions.details, '$.more_information')) AS more_information,
    markup_from_json_array(JSON_QUERY(editions.details, '$.what_you_need_to_know')) AS what_you_need_to_know,
    markup_from_json_array(JSON_QUERY(editions.details, '$.other_ways_to_apply')) AS other_ways_to_apply,
    markup_from_json_array(JSON_QUERY(editions.details, '$.cancellation_reason')) AS cancellation_reason,
    markup_from_json_array(JSON_QUERY(editions.details, '$.hidden_search_terms')) AS hidden_search_terms
  FROM public.publishing_api_editions_new_current AS editions
  INNER JOIN schema_map USING (schema_name)
  WHERE schema_map.govspeak_location = 'general'
),
general AS (
  SELECT
    * EXCEPT (
      introduction,
      information,
      need_to_know,
      introductory_paragraph,
      licence_overview,
      start_button_text,
      will_continue_on,
      more_information,
      what_you_need_to_know,
      other_ways_to_apply,
      cancellation_reason,
      hidden_search_terms
    ),
    ARRAY_TO_STRING([
      introduction.govspeak,
      information.govspeak,
      need_to_know.govspeak,
      introductory_paragraph.govspeak,
      licence_overview.govspeak,
      start_button_text.govspeak,
      will_continue_on.govspeak,
      more_information.govspeak,
      what_you_need_to_know.govspeak,
      other_ways_to_apply.govspeak,
      cancellation_reason.govspeak,
      hidden_search_terms.govspeak
    ], '\n\n') AS govspeak,
    ARRAY_TO_STRING([
      introduction.html,
      information.html,
      need_to_know.html,
      introductory_paragraph.html,
      licence_overview.html,
      start_button_text.html,
      will_continue_on.html,
      more_information.html,
      what_you_need_to_know.html,
      other_ways_to_apply.html,
      cancellation_reason.html,
      hidden_search_terms.html
    ], '\n\n') AS html,
  FROM general_content
),

-- govspeak and HTML content of document types that have content in the details.parts array
parts_content AS (
  SELECT
    editions.id AS edition_id,
    editions.document_id,
    editions.schema_name,
    editions.base_path,
    editions.title,
    part_index, -- zero-based
    STRING(JSON_QUERY(part, '$.slug')) AS part_slug,
    STRING(JSON_QUERY(part, '$.title')) AS part_title,
    markup_from_json_array(JSON_QUERY(part, '$.body')) AS content
  FROM public.publishing_api_editions_new_current AS editions
  INNER JOIN schema_map USING (schema_name)
  CROSS JOIN UNNEST(JSON_QUERY_ARRAY(editions.details, '$.parts')) AS part WITH OFFSET AS part_index
  WHERE schema_map.govspeak_location = 'part'
  AND JSON_TYPE(JSON_QUERY(editions.details, '$.parts')) = 'array'
  AND JSON_TYPE(JSON_QUERY(part, '$.body')) = 'array'
),
parts AS (
  SELECT
    * EXCEPT (content),
    content.govspeak AS govspeak,
    content.html AS html
  FROM parts_content
),

-- The first part of each document is available at two URLs: with and without
-- its slug. So duplicate the first part without its slug.
first_parts AS (
  SELECT
    edition_id,
    document_id,
    schema_name,
    base_path,
    title,
    FALSE AS is_part,
    part_index, -- The part that this record is derived from
    CAST(NULL AS STRING) AS part_slug,
    CAST(NULL AS STRING) AS part_title,
    govspeak,
    html
  FROM parts
  WHERE part_index = 0
),
-- Make parts like pages in their own right (concatenating the base_path and slug),
-- but leave enough metadata to be able to deconstruct them back to a true part.
all_parts AS (
  SELECT
    edition_id,
    document_id,
    schema_name,
    CONCAT(base_path, '/', part_slug) AS base_path,
    CONCAT(title, ': ', part_title) AS title,
    TRUE AS is_part,
    part_index, -- This being non-null isn't sufficient to identify parts
    part_slug, -- This being non-null is sufficient to identify parts
    part_title,
    govspeak,
    html
  FROM parts
),

combined AS (
  SELECT * FROM body
  UNION ALL SELECT * FROM body_content
  UNION ALL SELECT * FROM general

  -- Only the first part of each guide/travel_advice document, using only the base_path
  UNION ALL SELECT * FROM first_parts
  -- Every part of each guide/travel_advice document, concatenating the base_path and the slug
  UNION ALL SELECT * FROM all_parts
),

rendered AS (
  SELECT * REPLACE(
    COALESCE(html, JSON_VALUE(`${project_id}.functions.govspeak_to_html`(govspeak), '$.html')) AS html
  )
  FROM combined
),

extracts AS (
  SELECT
    *,
    `${project_id}.functions.html_to_text`(html) AS text,
    `${project_id}.functions.parse_html`(html, 'https://www.gov.uk' || base_path) AS extracted_content
  FROM rendered
)

SELECT
  * EXCEPT(extracted_content),
  ARRAY(
    SELECT
      STRUCT(
        line_number + 1 AS line_number,
        line
      )
    FROM UNNEST(SPLIT(text, "\n")) AS line WITH OFFSET AS line_number
  ) AS lines,
  dedup(
    ARRAY(
      SELECT
        STRUCT(
          JSON_EXTRACT_SCALAR(link, "$.link_url") AS url,
          JSON_EXTRACT_SCALAR(link, "$.link_url_bare") AS url_bare,
          JSON_EXTRACT_SCALAR(link, "$.link_text")
        )
      FROM UNNEST(JSON_EXTRACT_ARRAY(extracted_content, "$.hyperlinks")) AS link
    )
  ) AS hyperlinks,
  dedup(
    ARRAY(
      SELECT
        STRUCT(
          JSON_EXTRACT_SCALAR(abbreviation, "$.title") AS title, -- expansion
          JSON_EXTRACT_SCALAR(abbreviation, "$.text") AS text    -- abbreviation
        )
      FROM UNNEST(JSON_EXTRACT_ARRAY(extracted_content, "$.abbreviations")) AS abbreviation
    )
  ) AS abbreviations
FROM extracts
;

-- Delete rows from the public.content table where a newer edition of the same
-- document is now available.  The newer edition might be private, so use the
-- private editions as the source of the merge.
MERGE INTO
public.content AS target
USING private.publishing_api_editions_new_current AS source
ON source.document_id = target.document_id
WHEN matched THEN DELETE
;

-- Insert the content of new editions into the public.content table.
INSERT INTO public.content
SELECT * FROM public.content_new
;

END
