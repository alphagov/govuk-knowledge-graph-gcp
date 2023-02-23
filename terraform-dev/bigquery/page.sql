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
hyperlinks AS (
  SELECT
    url,
    -- Use DISTINCT because some links are in the table multiple times with
    -- different link_text
    ARRAY_AGG(DISTINCT link_url) AS hyperlinks
  FROM content.embedded_links
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
  withdrawn_at,
  withdrawn_explanation,
  pagerank,
  title,
  description,
  text,
  tagged_taxons.ancestor_titles AS taxons,
  primary_publishing_organisation.organisation AS primary_organisation,
  organisations.organisations,
  hyperlinks.hyperlinks,
  entities.entities
FROM graph.page
LEFT JOIN primary_publishing_organisation USING (url)
LEFT JOIN organisations USING (url)
LEFT JOIN hyperlinks USING (url)
LEFT JOIN entities USING (url)
LEFT JOIN tagged_taxons ON (tagged_taxons.url = 'https://www.gov.uk/' || content_id)
WHERE
  page.document_type IS NULL
  OR NOT page.document_type IN ('gone', 'redirect', 'placeholder', 'placeholder_person')
;
