USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///url.csv' AS line
FIELDTERMINATOR ','
CREATE (p:Page { url: line.url })
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts.csv' AS line
FIELDTERMINATOR ','
CREATE (p:Page { url: line.url })
SET
  p.part_index = toInteger(line.part_index),
  p.slug = line.slug,
  p.part_title = line.part_title
;

CREATE CONSTRAINT ON (p:Page) ASSERT p.url IS UNIQUE;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///document_type.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.document_type = line.document_type
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///phase.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.phase = line.phase
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///content_id.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.content_id = line.content_id
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///analytics_identifier.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.analytics_identifier = line.analytics_identifier
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///locale.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.locale = line.locale
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///publishing_app.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.publishing_app = line.publishing_app
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///updated_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.updated_at = line.updated_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///public_updated_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.public_updated_at = line.public_updated_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///first_published_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.first_published_at = line.first_published_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///withdrawn_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.withdrawn_at = line.`withdrawn_notice.withdrawn_at`
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///withdrawn_explanation.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.withdrawn_explanation = line.`withdrawn_notice.withdrawn_explanation`
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///title.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.title = line.title
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///description.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.description = line.description
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM 'file:///department_analytics_profile.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.department_analytics_profile = line.`details.department_analytics_profile`
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///body.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///body_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
WITH p, line
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[:HYPERLINKS_TO { link_url: line.link_url, link_text: coalesce(line.link_text, "") }]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///body_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///body_content_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
WITH p, line
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[:HYPERLINKS_TO { link_url: line.link_url, link_text: coalesce(line.link_text, "") }]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
WITH p, line
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[:HYPERLINKS_TO { link_url: line.link_url, link_text: coalesce(line.link_text, "") }]->(q)
;

// Load the content and hyperlinks of the root of each collecton of parts
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts_content.csv' AS line
FIELDTERMINATOR ','
FOREACH(ignore_me IN CASE WHEN toInteger(line.part_index) = 1 THEN [1] ELSE [] END |
  MERGE (p:Page { url: line.base_path })
  SET p.text = line.text
)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts_embedded_links.csv' AS line
FIELDTERMINATOR ','
FOREACH(ignore_me IN CASE WHEN toInteger(line.part_index) = 1 THEN [1] ELSE [] END |
  MERGE (p:Page { url: line.base_path })
  MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
  CREATE (p)-[:HYPERLINKS_TO { link_url: line.link_url, link_text: coalesce(line.link_text, "") }]->(q)
)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///place_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///place_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
WITH p, line
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[:HYPERLINKS_TO { link_url: line.link_url, link_text: coalesce(line.link_text, "") }]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///transaction_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///transaction_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
WITH p, line
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[:HYPERLINKS_TO { link_url: line.link_url, link_text: coalesce(line.link_text, "") }]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///step_by_step_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///step_by_step_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
WITH p, line
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[:HYPERLINKS_TO { link_url: line.link_url, link_text: coalesce(line.link_text, "") }]->(q)
;

// Create LINKS_TO relationship (expanded links)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///expanded_links.csv' AS line
FIELDTERMINATOR ','
MATCH
  (p:Page { url: line.from_url }),
  (q:Page { url: line.to_url })
CREATE (p)-[:LINKS_TO { link_target_type: line.link_type }]->(q)
;

// Transaction start button link (must come before button text)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///transaction_start_link.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
WITH p, line
MERGE (q:Page { url: line.link_url_bare })
CREATE (p)-[:TRANSACTION_STARTS_AT { link_url: line.link_url_bare }]->(q)
;

// Transaction start button text
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///start_button_text.csv' AS line
FIELDTERMINATOR ','
MATCH (:Page { url: line.url })-[r:TRANSACTION_STARTS_AT]->()
SET r.link_text = line.`details.start_button_text`
;

// Links from the roots of travel advice and guide pages
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts.csv' AS line
FIELDTERMINATOR ','
MATCH
  (part:Page { url: line.url }),
  (root:Page { url: line.base_path })
CREATE (root)-[r:HAS_PART { part_index: toInteger(line.part_index), slug: line.slug, part_title: line.part_title }]->(part)
;

// Taxon url override (like a redirect)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///url_override.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url }),
MERGE (q:Page { url: line.url_override })
CREATE (p)-[r:REDIRECTS_TO]->(q)
;

// Redirects
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///redirects.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.from }),
MERGE (q:Page { url: line.to })
CREATE (p)-[r:REDIRECTS_TO]->(q)
;

// Taxon levels
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///taxon_levels.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.taxon_level = line.level
;
