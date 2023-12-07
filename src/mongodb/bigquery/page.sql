-- Create a table of page nodes
TRUNCATE TABLE graph.page;
INSERT INTO graph.page
SELECT
  u.url,
  document_type.document_type,
  schema_name.schema_name,
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
  withdrawn_explanation.text AS withdrawn_explanation,
  title.title,
  internal_name.internal_name,
  description.description,
  department_analytics_profile.department_analytics_profile,
  c.text,
  CAST(NULL AS INT64) AS part_index,
  CAST(NULL AS STRING) AS slug,
  page_views.number_of_views AS page_views
FROM content.url AS u
LEFT JOIN content.document_type USING (url)
LEFT JOIN content.schema_name USING (url)
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
LEFT JOIN content.internal_name USING (url)
LEFT JOIN content.title USING (url)
LEFT JOIN content.description USING (url)
LEFT JOIN content.department_analytics_profile USING (url)
LEFT JOIN content.content AS c USING (url)
LEFT JOIN content.page_views USING (url)
;

-- Derive a table of parts nodes from their parent page nodes
TRUNCATE TABLE graph.part;
INSERT INTO graph.part
SELECT
  page.*
  REPLACE(
    parts.url AS url,
    parts.part_title AS title,
    c.text AS text,
    parts.part_index AS part_index,
    parts.slug AS slug,
    page_views.number_of_views AS page_views
  )
FROM graph.page
INNER JOIN content.parts ON page.url = parts.base_path
LEFT JOIN content.content AS c ON c.url = parts.url
LEFT JOIN content.page_views on (page_views.url = parts.url)
;
INSERT INTO graph.page SELECT * FROM graph.part;
