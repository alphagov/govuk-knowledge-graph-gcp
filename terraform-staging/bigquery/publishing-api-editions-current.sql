-- Maintains a table `public.publishing_api_editions_current` of one record per
-- document as it currently appears on the GOV.UK website and in the Content
-- API.
--
-- 1. Filter editions for ones since max(editions_current.updated_at).
-- 2. Query those editions for the current editions of those documents.
-- 3. Delete corresponding editions from editions_current and editions_online.
-- 4. Insert the new current editions into editions_current.
-- 5. Insert the new online editions into editions_online.

-- All documents of schema_name='redirect' define a redirect in the 'redirect'
-- column.  None do that aren't, so schema_name='redirect' is necessary and sufficient to
-- identify redirects.

BEGIN

-- The timestamp of the most recent edition so far
DECLARE max_updated_at TIMESTAMP DEFAULT (
  -- Coalesce for the case when editions_current is empty
  SELECT coalesce(max(updated_at), '0001-01-01 00:00:00+00')
  FROM public.publishing_api_editions_current
);

-- In case the same timestamp also exists in a so-far unseen record, delete that
-- record.  Then all records of that timestamp will be treated as though so-far
-- unseen.
DELETE FROM public.publishing_api_editions_current WHERE updated_at = max_updated_at;
-- A set of so-far unseen editions.
TRUNCATE TABLE private.publishing_api_editions_new;
INSERT INTO private.publishing_api_editions_new
  SELECT * FROM publishing_api.editions WHERE updated_at >= max_updated_at
;

-- Derive from the new editions a table of the latest edition per document, and
-- a flag indicating whether it has a presence online (whether a redirect,
  -- or embedded in other pages, or a page in its own right).
TRUNCATE TABLE public.publishing_api_editions_new_current;
INSERT INTO public.publishing_api_editions_new_current
  SELECT
    documents.content_id,
    documents.locale,
    publishing_api_editions_new.*,
    -- TODO: derive other values here
    (
      coalesce(content_store = 'live', false) -- Includes items that are only embedded in others.
      AND state <> 'superseded' -- Exclude this rare and illogical case
      AND coalesce(unpublishings.type <> 'vanish', true)
      AND (
        coalesce(left(schema_name, 11) <> 'placeholder', true)
        OR (
          -- schema_name must be checked again because short-circuit evaluation
          -- isn't available in this clause.
          coalesce(left(schema_name, 11) = 'placeholder', false)
          AND coalesce(unpublishings.type IN ('gone', 'redirect'), false)
        )
      )
    ) AS is_online
  FROM private.publishing_api_editions_new
  INNER JOIN publishing_api.documents ON documents.id = publishing_api_editions_new.document_id
  LEFT JOIN publishing_api.unpublishings ON unpublishings.edition_id = publishing_api_editions_new.id
  WHERE state <> 'draft'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY content_id, locale ORDER BY updated_at DESC) = 1
;

-- Delete rows from the editions_current table where a newer edition of the same
-- document is now available.
MERGE INTO
public.publishing_api_editions_current AS target
USING public.publishing_api_editions_new_current AS source
ON source.content_id = target.content_id AND source.locale = target.locale
WHEN matched THEN DELETE
;

-- Insert the new editions into the editions_current table
INSERT INTO public.publishing_api_editions_current
SELECT * FROM public.publishing_api_editions_new_current
;

END
