-- Create a table of page nodes
DELETE graph.page WHERE TRUE;
INSERT INTO graph.page
WITH tagged_taxons AS (
  SELECT
    is_tagged_to.url AS url,
    ARRAY_AGG(taxon_title.title) AS taxons
  FROM graph.is_tagged_to
  INNER JOIN content.taxon_levels ON (taxon_levels.url = is_tagged_to.taxon_url) -- gives us the URL of the taxon's homepage
  INNER JOIN content.title AS taxon_title ON (taxon_title.url = taxon_levels.homepage_url) -- gives us the title of the taxon's homepage
  GROUP BY
    url
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
  tagged_taxons.taxons
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
