-- Maintains a table `public.content`, derived from `public.markup`
--
-- 1. Fetch new markup since the last batch update from
--    public.markup_new.
-- 2. Extract plain text and other HTML elements.
-- 4. Delete outdated records from public.content.
-- 4. Insert new content into public.content.

BEGIN

TRUNCATE TABLE public.content_new;
INSERT INTO public.content_new
WITH extracts AS (
  SELECT
    edition_id,
    document_id,
    part_index,
    `${project_id}.functions.html_to_text`(html) AS text,
    `${project_id}.functions.parse_html`(html, 'https://www.gov.uk' || base_path) AS extracted_content
  FROM public.markup_new
)
SELECT
  edition_id,
  document_id,
  text,
  JSON_EXTRACT_ARRAY(extracted_content, "$.hyperlinks") AS hyperlinks,
  JSON_EXTRACT_ARRAY(extracted_content, "$.abbreviations") AS abbreviations
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
