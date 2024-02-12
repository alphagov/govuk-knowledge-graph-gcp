TRUNCATE TABLE search.page;
INSERT INTO search.page
WITH
-- Latest updated_at date per base path in the Publisher app database.
-- For mainstream content, this is more meaningful than the Publishing
-- API or Content API 'updated_at' or 'public_updated_at fields.'  Mainstream
-- editors don't tend to use 'public_updated_at', and 'updated_at' is polluted
-- by creation of new editions for techy reasons rather than editing reasons.
publisher_updated_at AS (
  SELECT
    url,
    MAX(updated_at) AS publisher_updated_at,
  FROM publisher.editions
  WHERE state='published'
  GROUP BY url
),
tagged_taxons AS (
  SELECT
    is_tagged_to.url AS url,
    -- Use DISTINCT because some pages are tagged to more than one taxon that
    -- share ancestors.
    ARRAY_AGG(DISTINCT taxon_ancestors.ancestor_title) AS ancestor_titles,
  FROM graph.is_tagged_to
  INNER JOIN graph.taxon_ancestors ON taxon_ancestors.url = is_tagged_to.taxon_url
  GROUP BY url
),
primary_publishing_organisation AS (
  SELECT
    link.from_content_id AS content_id,
    organisation.title
  FROM content.expanded_links_content_ids AS link
  INNER JOIN graph.organisation AS organisation ON (organisation.content_id = link.to_content_id)
  WHERE link_type = 'primary_publishing_organisation'
),
organisations AS (
  SELECT
    link.from_content_id AS content_id,
    ARRAY_AGG(organisation.title) AS titles
  FROM content.expanded_links_content_ids AS link
  INNER JOIN graph.organisation AS organisation ON (organisation.content_id = link.to_content_id)
  WHERE link_type = 'organisations'
  GROUP BY link.from_content_id
),
all_links AS (
  SELECT DISTINCT
    link_type,
    from_url as url,
    to_url as link_url
  FROM
    content.expanded_links
  UNION ALL
  SELECT DISTINCT
    "embedded" as link_type,
    url,
    link_url
  FROM
    content.embedded_links
  UNION ALL
  SELECT DISTINCT
    "transaction_start_link" AS link_type,
    url,
    link_url
  FROM
    content.transaction_start_link
),
links AS (
  SELECT
    url,
    ARRAY_AGG(
      STRUCT(
        link_url,
        link_type
      )
    ) AS hyperlink
  FROM
    all_links
  GROUP BY
    url
),
phone_numbers AS (
  SELECT
    url,
    ARRAY_AGG(standardised_number) as phone_numbers
  FROM
    graph.phone_number
  GROUP BY url
),
entities AS (
  WITH page_type_count AS (
    SELECT
      url,
      type,
      sum(total_count) AS total_count
    FROM `cpto-content-metadata.named_entities.named_entities_counts`
    GROUP BY
      url,
      type
  )
  SELECT
    url,
    ARRAY_AGG(STRUCT(type, total_count)) AS entities
  FROM page_type_count
  GROUP BY url
)
SELECT
  page.url,
  document_type AS documentType,
  content_id AS contentId,
  locale,
  publishing_app,
  first_published_at,
  public_updated_at,
  publisher_updated_at.publisher_updated_at,
  withdrawn_at,
  withdrawn_explanation,
  page_views.number_of_views AS page_views,
  /*
  Title is preferred to internal name because it is typically of better quality;
  internal name should be used if title is not unique / repeated.
  */
  CASE WHEN
    COUNT(page.title) OVER (PARTITION BY page.title) = 1 THEN page.title
    ELSE COALESCE(page.internal_name, page.title)
  END AS name,
  description,
  text,
  tagged_taxons.ancestor_titles AS taxons,
  primary_publishing_organisation.title AS primary_organisation,
  organisations.titles AS organisations,
  links.hyperlink AS hyperlinks,
  phone_numbers.phone_numbers,
  entities.entities
FROM graph.page
LEFT JOIN primary_publishing_organisation USING (content_id)
LEFT JOIN organisations USING (content_id)
LEFT JOIN links USING (url)
LEFT JOIN phone_numbers USING (url)
LEFT JOIN entities USING (url)
LEFT JOIN private.page_views USING (url)
LEFT JOIN tagged_taxons ON (tagged_taxons.url = 'https://www.gov.uk/' || content_id)
LEFT JOIN publisher_updated_at ON (STARTS_WITH(page.url, publisher_updated_at.url))
WHERE
  page.document_type IS NULL
  OR NOT page.document_type IN ('gone', 'redirect', 'placeholder', 'placeholder_person')
;
