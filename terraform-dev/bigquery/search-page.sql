-- A table for the GovSearch app
-- One row per 'page' (document, or part of a document that has its own URL, or
-- snippet that is included in other pages)

TRUNCATE TABLE search.page;
INSERT INTO search.page
WITH
  editions AS (
    SELECT editions.*
    FROM public.publishing_api_editions_current AS editions
    LEFT JOIN public.publishing_api_unpublishings_current
      AS unpublishings
      ON (unpublishings.edition_id = editions.id)
    WHERE (unpublishings.edition_id IS NULL OR unpublishings.type = 'withdrawal')
    AND editions.document_type NOT IN ('gone', 'redirect')
  ),
  withdrawals AS (
    SELECT
      edition_id,
      unpublished_at AS withdrawn_at,
      explanation AS withdrawn_explanation
    FROM public.publishing_api_unpublishings_current
    WHERE type = 'withdrawal'
  ),
  primary_publishing_organisation AS (
    SELECT
      links.source_edition_id AS edition_id,
      editions.title AS title
    FROM public.publishing_api_links_current AS links
    INNER JOIN editions ON editions.id = links.target_edition_id
    WHERE links.type = 'primary_publishing_organisation'
    -- Assume that the organisation has a document in the 'en' locale.
    -- If we allow every locale, then we will duplicate pages whose
    -- primary_publishing_organisation has documents in multiple locales.
    AND editions.locale = 'en'
  ),
  organisations AS (
    SELECT
      links.source_edition_id AS edition_id,
      ARRAY_AGG(DISTINCT editions.title) AS titles
    FROM public.publishing_api_links_current AS links
    INNER JOIN editions ON editions.id = links.target_edition_id
    WHERE links.type = 'organisations'
    GROUP BY links.source_edition_id
  ),
  publisher_updated_at AS (
  -- Latest updated_at date per base path in the Publisher app database.
  -- For mainstream content, this is more meaningful than the Publishing
  -- API or Content API 'updated_at' or 'public_updated_at fields.'  Mainstream
  -- editors don't tend to use 'public_updated_at', and 'updated_at' is polluted
  -- by creation of new editions for techy reasons rather than editing reasons.
  SELECT
    url,
    MAX(updated_at) AS publisher_updated_at,
  FROM publisher.editions
  WHERE state='published'
  GROUP BY url
),
taxons AS (
  -- One row per taxon.
  -- Its edition_id, and an array of DISTINCT titles of it and its ancestors
  -- back to the root taxon.
  --
  -- This supports filtering by the name of a page's taxon or the ancestors of
  -- that taxon.
  --
  -- Taxonomy titles aren't unique. Most of them can be disambiguated by using
  -- their internal_name instead, but often the internal_name isn't suitable for
  -- use elsewhere than a publishing app. Titles seem to be duplicated when they
  -- relate to a particular country, such as "Help and services around the
  -- world", the internal name of which is "Help and services around the world
  -- (Algeria)". The GovSearch app probably shouldn't list every country's
  -- version of that taxon, so it lists the generic version. Those taxons
  -- usually have an associated_taxons link to "UK help and services in Algeria"
  -- (or whichever country) anyway, so if users need to be specific then they
  -- can filter by that taxon.
  SELECT
    taxonomy.edition_id,
    ARRAY_AGG(DISTINCT editions.title) AS titles
  FROM public.taxonomy,
  UNNEST(all_ancestors) AS ancestor
  INNER JOIN editions ON editions.id = ancestor.edition_id
  GROUP BY taxonomy.edition_id
),
all_links AS (
  SELECT
    links.type AS link_type,
    editions.base_path,
    "https://www.gov.uk" || editions.base_path as link_url
  FROM
    public.publishing_api_links_current AS links
  INNER JOIN editions ON editions.id = links.source_edition_id
  WHERE editions.base_path IS NOT NULL
  UNION ALL
  SELECT
    "embedded" as link_type,
    base_path, -- the base_path of the document or part
    hyperlink.url AS link_url
  FROM
    public.content,
    UNNEST(hyperlinks) AS hyperlink
  UNION ALL
  SELECT
    "transaction_start_link" AS link_type,
    editions.base_path,
    url AS link_url
  FROM
    public.start_button_links
  INNER JOIN editions ON editions.id = start_button_links.edition_id
),
distinct_links AS (
  SELECT DISTINCT * FROM all_links
),
links AS (
  SELECT
    base_path,
    ARRAY_AGG(
      STRUCT(
        link_url,
        link_type
      )
    ) AS hyperlinks
  FROM all_links
  GROUP BY base_path
),
phone_numbers AS (
  SELECT
    p.edition_id,
    ARRAY_AGG(phone_number.standardised_number) as phone_numbers
  FROM public.phone_numbers as p,
  UNNEST(phone_numbers) AS phone_number
  GROUP BY edition_id
),
pages AS (
  SELECT
    editions.id AS edition_id,
    COALESCE(content.base_path, editions.base_path) AS base_path,
    "https://www.gov.uk" || COALESCE(content.base_path, editions.base_path) AS url
  FROM editions
  LEFT JOIN public.content ON content.edition_id = editions.id
  WHERE TRUE
  AND editions.base_path IS NOT NULL
  -- Exclude pages that duplicate the first part of a multipart document.
  -- Equivalent statements are:
  -- `content.part_index IS NULL OR content.part_index > 1`
  -- `(NOT content.is_part) OR content.part_index > 1`
  AND content.is_part OR (content.part_index IS NULL)
)
SELECT
  pages.url,
  editions.document_type AS documentType,
  editions.content_id AS contentId,
  editions.locale,
  editions.publishing_app,
  editions.first_published_at,
  editions.public_updated_at,
  publisher_updated_at.publisher_updated_at,
  withdrawals.withdrawn_at,
  withdrawals.withdrawn_explanation,
  page_views.number_of_views AS page_views,
  -- content.title is "title: part title" if it is a part of a document, but it
  -- doesn't include every schema_name, so fall back to editions.title.
  COALESCE(content.title, editions.title) AS title,
  editions.description,
  content.text,
  taxons.titles AS taxons,
  primary_publishing_organisation.title AS primary_organisation,
  COALESCE(organisations.titles, []) AS organisations,
  links.hyperlinks,
  phone_numbers.phone_numbers
FROM pages
INNER JOIN editions ON editions.id = pages.edition_id -- one row per document
LEFT JOIN withdrawals ON withdrawals.edition_id = pages.edition_id
LEFT JOIN primary_publishing_organisation ON primary_publishing_organisation.edition_id = pages.edition_id
LEFT JOIN organisations ON organisations.edition_id = pages.edition_id
LEFT JOIN phone_numbers ON phone_numbers.edition_id = pages.edition_id
LEFT JOIN taxons ON taxons.edition_id = pages.edition_id
-- one publisher_updated_at per multipart document
LEFT JOIN publisher_updated_at ON STARTS_WITH(pages.url, publisher_updated_at.url)
LEFT JOIN public.content -- one row per document or part
  ON content.base_path = pages.base_path -- includes the slug of parts
LEFT JOIN links
  ON links.base_path = pages.base_path -- includes the slug of parts
LEFT JOIN private.page_views
  ON page_views.url = pages.url -- includes the slug of parts
;
