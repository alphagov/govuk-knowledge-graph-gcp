USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_url.csv' AS line
FIELDTERMINATOR ','
CREATE (p:Role { url: line.url })
;

CREATE CONSTRAINT ON (p:Role) ASSERT p.url IS UNIQUE;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_document_type.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.documentType = line.document_type
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_phase.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.phase = line.phase
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_content_id.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.contentId = line.content_id
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_locale.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.locale = line.locale
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_publishing_app.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.publishingApp = line.publishing_app
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_updated_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.updatedAt = line.updated_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_public_updated_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.publicUpdatedAt = line.public_updated_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_first_published_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.firstPublishedAt = line.first_published_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_title.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.title = line.title
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_description.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.description = line.description
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_content_text.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Role { url: line.url })
SET p.text = line.text
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_redirects.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.from })
MATCH (q:Page { url: line.to })
CREATE (p)-[r:REDIRECTS_TO]->(q)
;

// Link to home pages of roles that have base_paths
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///role_base_path.csv' AS line
FIELDTERMINATOR ','
MATCH (r:Role { url: line.url })
MATCH (p:Page { url: "https://www.gov.uk" + line.base_path, locale: 'en' })
CREATE (r)-[:HAS_HOMEPAGE]->(p)
;
