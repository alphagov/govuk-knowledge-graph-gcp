-- Recreate the legacy graph.page table from the 'public' dataset
--
-- Differences:
--
-- * The legacy table included URLs derived from content that don't really exist
--   and that can be omitted with `schema_name is not null`
-- * The legacy table included redirects from the Content API that don't join to
--   current editions from the Publishing API, but do exist on the web. The
--   redirected URLs aren't discoverable, so we exclude them from the 'public'
--   dataset, so they are omitted here.  A disadvantage is that it won't be
--   possible to 'follow' some redirects without checking them with a GET
--   request.

TRUNCATE TABLE graph.page;
INSERT INTO graph.page
WITH
  editions AS (
    SELECT editions.*
    FROM public.publishing_api_editions_current AS editions
    WHERE editions.base_path IS NOT NULL
  ),
  withdrawals AS (
    SELECT
      edition_id,
      unpublished_at AS withdrawn_at,
      explanation AS withdrawn_explanation
    FROM public.publishing_api_unpublishings_current
    WHERE type = 'withdrawal'
),
pages AS (
  SELECT
    editions.id AS edition_id,
    COALESCE(content.base_path, editions.base_path) AS base_path,
    "https://www.gov.uk" || COALESCE(content.base_path, editions.base_path) AS url
  FROM editions
  LEFT JOIN public.content ON content.edition_id = editions.id
  WHERE TRUE
  -- Omit the main page of multi-part documents, in favour of its duplicate that
  -- has a slug. For example, include the following:
  --
  --   /main-page/first-part
  --   /main-page/second-part
  --
  -- Omit the following:
  --
  --   /main-page
  AND (
    content.is_part IS NULL   -- Include documents that aren't multipart
    OR content.is_part        -- Omit the main page that doesn't have a slug
 )
)
SELECT
  pages.url,
  editions.document_type,
  editions.schema_name,
  editions.phase,
  editions.content_id,
  editions.analytics_identifier,
  JSON_value(editions.details, "$.acronym") AS acronym,
  editions.locale,
  editions.publishing_app,
  editions.updated_at,
  editions.first_published_at,
  editions.public_updated_at,
  withdrawals.withdrawn_at,
  withdrawals.withdrawn_explanation,
  -- content.title is "title: part title" if it is a part of a document, but it
  -- doesn't include every schema_name, so fall back to editions.title.
  COALESCE(content.title, editions.title) AS title,
  JSON_value(editions.details, "$.internal_name") AS internal_name,
  editions.description,
  JSON_value(editions.details, "$.department_analytics_profile") AS department_analytics_profile,
  content.text,
  content.part_index,
  content.part_slug AS slug
FROM pages
INNER JOIN editions ON editions.id = pages.edition_id -- one row per document
LEFT JOIN withdrawals ON withdrawals.edition_id = pages.edition_id
LEFT JOIN public.content -- one row per document or part
  ON content.base_path = pages.base_path -- includes the slug of parts
;
