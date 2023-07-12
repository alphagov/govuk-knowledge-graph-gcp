-- Create a table of role nodes
TRUNCATE TABLE graph.role;
INSERT INTO graph.role
SELECT
  role_url.url,
  role_document_type.document_type,
  role_schema_name.schema_name,
  role_phase.phase,
  role_content_id.content_id,
  role_locale.locale,
  role_publishing_app.publishing_app,
  role_updated_at.updated_at,
  role_public_updated_at.public_updated_at,
  role_first_published_at.first_published_at,
  role_title.title,
  role_description.description,
  role_content.text
FROM content.role_url
LEFT JOIN content.role_document_type USING (url)
LEFT JOIN content.role_schema_name USING (url)
LEFT JOIN content.role_phase USING (url)
LEFT JOIN content.role_content_id USING (url)
LEFT JOIN content.role_locale USING (url)
LEFT JOIN content.role_publishing_app USING (url)
LEFT JOIN content.role_updated_at USING (url)
LEFT JOIN content.role_public_updated_at USING (url)
LEFT JOIN content.role_first_published_at USING (url)
LEFT JOIN content.role_title USING (url)
LEFT JOIN content.role_description USING (url)
LEFT JOIN content.role_content USING (url)
;
