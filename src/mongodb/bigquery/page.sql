-- Create a table of page nodes
DELETE graph.page WHERE TRUE;
INSERT INTO graph.page
WITH
tagged_taxons_including_duplicates AS (
  -- One row per url per tagged taxon per ancestor, then aggregate the
  -- taxon/title pairs into one array, and ancestor/title pairs into another
  -- array.  Those arrays will contain duplicates, which will be dealt with in a
  -- subsequent query.
  SELECT
    is_tagged_to.url AS url,
    ARRAY_AGG(STRUCT(is_tagged_to.taxon_url, taxon_title.title AS taxon_title)) AS taxons,
    ARRAY_AGG(STRUCT(taxon_ancestors.ancestor_url, taxon_ancestors.ancestor_title)) AS ancestors,
  FROM graph.is_tagged_to
  -- content.taxon_levels gives us the URL of the taxon's homepage
  INNER JOIN content.taxon_levels ON (taxon_levels.url = is_tagged_to.taxon_url)
   -- content.title gives us the title of the taxon's homepage
  INNER JOIN content.title AS taxon_title ON (taxon_title.url = taxon_levels.homepage_url)
  -- root taxons don't have ancestors, so don't inner join
  LEFT JOIN graph.taxon_ancestors ON taxon_ancestors.url = is_tagged_to.taxon_url
  GROUP BY url
),
tagged_taxons AS (
  -- Remove duplicates from arrays of taxon/title pairs and ancestor/title
  -- pairs.
  SELECT
    url,
    -- array column of distinct taxon/title pairs
    ( SELECT
        -- 2. Aggregate the taxon/title pairs again
        ARRAY_AGG(STRUCT(taxon_url, taxon_title))
      FROM (
        -- 1. Unnest the taxon/title pairs and deduplicate
        SELECT DISTINCT
          taxon_url,
          taxon_title
        FROM UNNEST(taxons)
      )
    ) AS taxons,
    -- array column of distinct ancestor/title pairs
    ( SELECT
      -- 2. Aggregate the ancestor/title pairs again
      ARRAY_AGG(STRUCT(ancestor_url, ancestor_title))
      FROM (
        -- 1. Unnest the ancestor/title pairs and deduplicate
        SELECT DISTINCT
          ancestor_url,
          ancestor_title
        FROM
          UNNEST(ancestors)
      )
    ) AS ancestors
  FROM tagged_taxons_including_duplicates
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
)
SELECT
  u.url,
  document_type.document_type,
  phase.phase,
  content_id.content_id,
  analytics_identifier.analytics_identifier,
  acronym.acronym,
  locale.locale,
  publishing_app.publishing_app,
  updated_at.updated_at,
  public_updated_at.public_updated_at,
  first_published_at.first_published_at,
  withdrawn_at.withdrawn_at,
  withdrawn_explanation.withdrawn_explanation,
  title.title,
  description.description,
  department_analytics_profile.department_analytics_profile,
  c.text,
  CAST(NULL AS INT64) AS part_index,
  CAST(NULL AS STRING) AS slug,
  pagerank.pagerank,
  -- Extract only the titles of the url/title pairs, by unnesting and
  -- re-aggregating
  (select ARRAY_AGG(taxon_title) from unnest(tagged_taxons.taxons)) AS taxon_titles,
  (select ARRAY_AGG(ancestor_title) from unnest(tagged_taxons.ancestors)) AS ancestor_titles,
  primary_publishing_organisation.organisation,
  organisations.organisations,
  hyperlinks.hyperlinks
FROM content.url AS u
LEFT JOIN content.document_type USING (url)
LEFT JOIN content.phase USING (url)
LEFT JOIN content.content_id USING (url)
LEFT JOIN content.analytics_identifier USING (url)
LEFT JOIN content.acronym USING (url)
LEFT JOIN content.locale USING (url)
LEFT JOIN content.publishing_app USING (url)
LEFT JOIN content.updated_at USING (url)
LEFT JOIN content.public_updated_at USING (url)
LEFT JOIN content.first_published_at USING (url)
LEFT JOIN content.withdrawn_at USING (url)
LEFT JOIN content.withdrawn_explanation USING (url)
LEFT JOIN content.title USING (url)
LEFT JOIN content.description USING (url)
LEFT JOIN content.department_analytics_profile USING (url)
LEFT JOIN content.content AS c USING (url)
LEFT JOIN content.pagerank USING (url)
LEFT JOIN primary_publishing_organisation USING (url)
LEFT JOIN organisations USING (url)
LEFT JOIN hyperlinks USING (url)
LEFT JOIN tagged_taxons ON (tagged_taxons.url = 'https://www.gov.uk/' || content_id.content_id)
;

-- Derive a table of parts nodes from their parent page nodes
DELETE graph.part WHERE TRUE;
INSERT INTO graph.part
SELECT
  page.*
  REPLACE(
    parts.url AS url,
    page.document_type || "_part" AS document_type,
    parts.part_title AS title,
    parts.part_index AS part_index,
    parts.slug AS slug
  )
FROM graph.page
INNER JOIN content.parts ON page.url = parts.base_path
;
INSERT INTO graph.page SELECT * FROM graph.part;
