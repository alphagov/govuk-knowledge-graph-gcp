DELETE search.page WHERE TRUE;
INSERT INTO search.page
WITH
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
    expanded_links.from_url AS url,
    organisation.title AS organisation
  FROM content.expanded_links AS expanded_links
  INNER JOIN content.title AS organisation ON (organisation.url = expanded_links.to_url)
  WHERE link_type = 'primary_publishing_organisation'
),
organisations AS (
  SELECT
    expanded_links.from_url AS url,
    ARRAY_AGG(organisation.title) AS organisations
  FROM content.expanded_links AS expanded_links
  INNER JOIN content.title AS organisation ON (organisation.url = expanded_links.to_url)
  WHERE link_type = 'organisations'
  GROUP BY expanded_links.from_url
),
all_links AS (
  SELECT
    from_url as url, 
    to_url as link_url
  FROM
    content.expanded_links
  UNION ALL
  SELECT
    url,
    link_url
  FROM
    content.embedded_links
  UNION ALL
  SELECT
    url,
    link_url
  FROM
    content.transaction_start_link
),
links AS (
  SELECT
    url, 
    ARRAY_AGG(DISTINCT link_url) as link_url
  FROM 
    all_links
  GROUP BY
    url
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
  withdrawn_at,
  withdrawn_explanation,
  page_views,
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
  primary_publishing_organisation.organisation AS primary_organisation,
  organisations.organisations,
  links.link_url,
  entities.entities
FROM graph.page
LEFT JOIN primary_publishing_organisation USING (url)
LEFT JOIN organisations USING (url)
LEFT JOIN links USING (url)
LEFT JOIN entities USING (url)
LEFT JOIN tagged_taxons ON (tagged_taxons.url = 'https://www.gov.uk/' || content_id)
WHERE
  page.document_type IS NULL
  OR NOT page.document_type IN ('gone', 'redirect', 'placeholder', 'placeholder_person')
;
