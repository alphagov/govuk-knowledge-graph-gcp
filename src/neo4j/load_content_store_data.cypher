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
  p:Chapter,
  p.chapterNumber = toInteger(line.part_index),
  p.slug = line.slug,
  p.title = line.part_title
;

CREATE CONSTRAINT ON (p:Page) ASSERT p.url IS UNIQUE;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///document_type.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.documentType = line.document_type
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
SET p.contentID = line.content_id
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///analytics_identifier.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.analyticsIdentifier = line.analytics_identifier
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///acronym.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.acronym = line.`details.acronym`
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
SET p.publishingApp = line.publishing_app
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///updated_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.updatedAt = line.updated_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///public_updated_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.publicUpdatedAt = line.public_updated_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///first_published_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.firstPublishedAt = line.first_published_at
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///withdrawn_at.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.withdrawnAt = line.`withdrawn_notice.withdrawn_at`
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///withdrawn_explanation.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.withdrawnExplanation = line.`withdrawn_notice.withdrawn_explanation`
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
SET p.departmentAnalyticsProfile = line.`details.department_analytics_profile`
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///body.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

// coalesce() handles a handful of links that have malformed URLs, or empty link
// text.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///body_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[r:HYPERLINKS_TO {
  linkUrl: line.link_url,
  linkText: coalesce(line.link_text, "")
}]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///body_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

// coalesce() handles a handful of links that have malformed URLs, or empty link
// text.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///body_content_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[r:HYPERLINKS_TO {
  linkUrl: line.link_url,
  linkText: coalesce(line.link_text, "")
}]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

// coalesce() handles a handful of links that have malformed URLs, or empty link
// text.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[r:HYPERLINKS_TO {
  linkUrl: line.link_url,
  linkText: coalesce(line.link_text, "")
}]->(q)
;

// Load the content and hyperlinks of the root of each collecton of parts
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts_content.csv' AS line
FIELDTERMINATOR ','
FOREACH(ignore_me IN CASE WHEN toInteger(line.part_index) = 0 THEN [1] ELSE [] END |
  MATCH (p:Page { url: line.base_path })
  SET p.text = line.text
)
;

// coalesce() handles a handful of links that have malformed URLs, or empty link
// text.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts_embedded_links.csv' AS line
FIELDTERMINATOR ','
FOREACH(ignore_me IN CASE WHEN toInteger(line.part_index) = 0 THEN [1] ELSE [] END |
  MATCH (p:Page { url: line.base_path })
  MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
  CREATE (p)-[r:HYPERLINKS_TO {
    linkUrl: line.link_url,
    linkText: coalesce(line.link_text, "")
  }]->(q)
)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///place_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

// coalesce() handles a handful of links that have malformed URLs, or empty link
// text.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///place_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[r:HYPERLINKS_TO {
  linkUrl: line.link_url,
  linkText: coalesce(line.link_text, "")
}]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///transaction_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

// coalesce() handles a handful of links that have malformed URLs, or empty link
// text.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///transaction_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[r:HYPERLINKS_TO {
  linkUrl: line.link_url,
  linkText: coalesce(line.link_text, "")
}]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///step_by_step_content.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.text = line.text
;

// coalesce() handles a handful of links that have malformed URLs, or empty link
// text.
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///step_by_step_embedded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
MERGE (q:Page { url: coalesce(line.link_url_bare, line.link_url, "") })
CREATE (p)-[r:HYPERLINKS_TO {
  linkUrl: line.link_url,
  linkText: coalesce(line.link_text, "")
}]->(q)
;

// Create LINKS_TO relationship (expanded links)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///expanded_links.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.from_url })
MATCH (q:Page { url: line.to_url })
CREATE (p)-[:LINKS_TO { linkTargetType: line.link_type, linkIndex: line.link_index }]->(q)
;

// Remove self-links, which are pages that are translations of themselves
MATCH (n)-[r:LINKS_TO {link_target_type: 'available_translations'}]-(n)
DELETE r
;

// Reuse `transaction_starts_at` links as `HYPERLINKS_TO`.
MATCH (p)-[:LINKS_TO {link_target_type: 'transaction_starts_at'}]-(q)
CREATE (p)-[:HYPERLINKS_TO]-(q)
;

// Reuse `organisations` links as `HAS_ORGANISATION`.
MATCH (p)-[:LINKS_TO {link_target_type: 'organisations'}]-(q)
CREATE (p)-[:HAS_ORGANISATIONS]-(q)
;

// Reuse `primary_publishing_organisation` links as `HAS_PRIMARY_PUBLISHING_ORGANISATION`.
MATCH (p)-[:LINKS_TO {link_target_type: 'primary_publishing_organisation'}]-(q)
CREATE (p)-[:HAS_PRIMARY_PUBLISHING_ORGANISATION]-(q)
;

// Reuse `original_primary_publishing_organisation` links as `HAS_ORIGINAL_PRIMARY_PUBLISHING_ORGANISATION`.
MATCH (p)-[:LINKS_TO {link_target_type: 'original_primary_publishing_organisation'}]-(q)
CREATE (p)-[:HAS_ORIGINAL_PRIMARY_PUBLISHING_ORGANISATION]-(q)
;

// Reuse `supporting_organisations` links as `HAS_SUPPORTING_ORGANISATIONS`.
MATCH (p)-[:LINKS_TO {link_target_type: 'supporting_organisations'}]-(q)
CREATE (q)-[:HAS_SUPPORTING_ORGANISATIONS]-(p)
;

// Reuse `ordered_successor_organisations` links as `HAS_SUPERSEDED`.
MATCH (p)-[:LINKS_TO {link_target_type: 'ordered_successor_organisations'}]-(q)
CREATE (q)-[:HAS_SUPERSEDED]-(p)
;

// Reuse `suggested_ordered_related_items` links as `HYPERLINKS_TO`.
MATCH (p)-[:LINKS_TO {link_target_type: 'suggested_ordered_related_items'}]-(q)
CREATE (p)-[:HYPERLINKS_TO]-(q)
;

// Reuse `ordered_related_items` links as `HYPERLINKS_TO`.
MATCH (p)-[:LINKS_TO {link_target_type: 'ordered_related_items'}]-(q)
CREATE (p)-[:HYPERLINKS_TO]-(q)
;

// Reuse `ordered_related_items_overrides` links as `HYPERLINKS_TO`.
MATCH (p)-[:LINKS_TO {link_target_type: 'ordered_related_items_overrides'}]-(q)
CREATE (p)-[:HYPERLINKS_TO]-(q)
;

// Reuse `suggested_ordered_related_items` links as `HAS_SUGGESTED_ORDERED_RELATED_ITEMS`.
MATCH (p)-[:LINKS_TO {link_target_type: 'suggested_ordered_related_items'}]-(q)
CREATE (p)-[:HAS_SUGGESTED_ORDERED_RELATED_ITEMS]-(q)
;

// Reuse `taxons` links as `IS_TAGGED_TO`.
MATCH (p)-[:LINKS_TO {link_target_type: 'taxons'}]-(q)
CREATE (q)-[:IS_TAGGED_TO]-(p)
;

// Reuse `child` links as `HAS_CHILD`.  These are organisations.
MATCH (p)-[:LINKS_TO {link_target_type: 'children'}]-(q)
CREATE (q)-[:HAS_CHILD]-(p)
;

// Reuse `parent_taxons` links as `HAS_PARENT`.
MATCH (p)-[:LINKS_TO {link_target_type: 'parent_taxons'}]-(q)
CREATE (q)-[:HAS_PARENT]-(p)
;

// Transaction start button link (must come before button text)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///transaction_start_link.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
MERGE (q:Page { url: line.link_url_bare })
CREATE (p)-[:TRANSACTION_STARTS_AT { linkUrl: line.link_url_bare }]->(q)
;

// Transaction start button text
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///start_button_text.csv' AS line
FIELDTERMINATOR ','
MATCH (:Page { url: line.url })-[r:TRANSACTION_STARTS_AT]->()
SET r.linkText = line.`details.start_button_text`
;

// Links from the roots of travel advice and guide pages
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts.csv' AS line
FIELDTERMINATOR ','
MATCH (c:Chapter { url: line.url })
MATCH (p:Page { url: line.base_path })
CREATE (p)-[r:HAS_CHAPTER {
  chapterNumber: toInteger(line.part_index),
  slug: line.slug,
  title: line.part_title
}]->(c)
;

// Organisations, persons, and taxons
MATCH (p:Page { documentType: 'organisation' })
CREATE (q:Organisation {
  url: 'https://www.gov.uk/' + p.contentID
  name: p.title,
  orgID: p.analyticsIdentifier,
  contentId: p.contentID,
  status: p.phase,
  abbreviation: p.acronym
})
CREATE (q)-[:HAS_HOMEPAGE]-(p)
;

MATCH (p:Page { documentType: 'person' })
CREATE (q:Person {
  url: 'https://www.gov.uk/' + p.contentID
  name: p.title,
  contentID: p.contentID
})
CREATE (q)-[:HAS_HOMEPAGE]-(p)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///redirects.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.from }),
MATCH (q:Page { url: line.to })
CREATE (p)-[r:REDIRECTS_TO]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///taxon_levels.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
CREATE (q:Taxon {
  url: 'https://www.gov.uk/' + p.contentID
  name: p.title,
  contentID: p.contentID,
  level: line.level
})
CREATE (q)-[:HAS_HOMEPAGE]-(p)
;

MATCH (n:Page) WHERE left(n.url, 18) <> "https://www.gov.uk"
SET n:ExternalPage
REMOVE n:Page
;
