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
  p:Part,
  p.partNumber = toInteger(line.part_index),
  p.documentType = "part",
  p.slug = line.slug,
  p.title = line.part_title
;

CREATE CONSTRAINT ON (p:Page) ASSERT p.url IS UNIQUE;
CREATE CONSTRAINT ON (p:Organisation) ASSERT p.url IS UNIQUE;
CREATE CONSTRAINT ON (p:Taxon) ASSERT p.url IS UNIQUE;
CREATE CONSTRAINT ON (p:BankHoliday) ASSERT p.url IS UNIQUE;
CREATE CONSTRAINT ON (p:Date) ASSERT p.url IS UNIQUE;
CREATE CONSTRAINT ON (p:Division) ASSERT p.url IS UNIQUE;
CREATE CONSTRAINT ON (p:Person) ASSERT p.url IS UNIQUE;

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
SET p.contentId = line.content_id
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
  linkText: coalesce(line.link_text, ""),
  linkCount: line.count
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
  linkText: coalesce(line.link_text, ""),
  linkCount: line.count
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
  linkText: coalesce(line.link_text, ""),
  linkCount: line.count
}]->(q)
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
  linkText: coalesce(line.link_text, ""),
  linkCount: line.count
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
  linkText: coalesce(line.link_text, ""),
  linkCount: line.count
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
  linkText: coalesce(line.link_text, ""),
  linkCount: line.count
}]->(q)
;

// Transaction start button link (must come before button text)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///transaction_start_link.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
MERGE (q:Page { url: line.link_url_bare })
CREATE (p)-[:TRANSACTION_STARTS_AT { linkUrl: line.link_url_bare }]->(q)
CREATE (s:Transaction {
  url: line.link_url_bare,
  name: p.title,
  description: p.description
})-[:HAS_START_PAGE]->(p)
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
// And set the text of the root to be the text of the first part
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///parts.csv' AS line
FIELDTERMINATOR ','
MATCH (c:Part { url: line.url })
MATCH (p:Page { url: line.base_path })
CREATE (p)-[r:HAS_PART {
  partNumber: toInteger(line.part_index),
  slug: line.slug,
  title: line.part_title
}]->(c)
SET
  p.text = c.text,
  c.publishingApp = p.publishingApp,
  c.contentId = p.contentId,
  c.locale = p.locale,
  c.firstPublishedAt = p.firstPublishedAt,
  c.updatedAt = p.updatedAt,
  c.withdrawnAt = p.withdrawnAt,
  c.withdrawnExplanation = c.withdrawnExplanation
WITH c
MATCH (c)-[r:HYPERLINKS_TO]->(q:Page)
CREATE (p)-[:HYPERLINKS_TO {
  linkUrl: r.linkUrl,
  linkText: r.linkText,
  linkCount: r.linkCount
}]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///redirects.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.from })
MATCH (q:Page { url: line.to })
CREATE (p)-[r:REDIRECTS_TO]->(q)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///url_override.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
MATCH (q:Page { url: line.url_override })
CREATE (p)-[r:REDIRECTS_TO]->(q)
;

// Organisations, persons, and taxons
MATCH (p:Page { documentType: 'organisation', locale: 'en' })
CREATE (q:Organisation {
  url: 'https://www.gov.uk/' + p.contentId,
  name: p.title,
  orgId: p.analyticsIdentifier,
  contentId: p.contentId,
  status: p.phase,
  abbreviation: p.acronym
})
CREATE (q)-[:HAS_HOMEPAGE]->(p)
;

MATCH (p:Page { documentType: 'person', locale: 'en' })
CREATE (q:Person {
  url: 'https://www.gov.uk/' + p.contentId,
  name: p.title,
  contentId: p.contentId
})
CREATE (q)-[:HAS_HOMEPAGE]->(p)
;

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///taxon_levels.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
CREATE (q:Taxon {
  url: 'https://www.gov.uk/' + p.contentId,
  name: p.title,
  contentId: p.contentId,
  level: line.level
})
CREATE (q)-[:HAS_HOMEPAGE]->(p)
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
MATCH (n)-[r:LINKS_TO {linkTargetType: 'available_translations'}]->(n)
DELETE r
;

// Reuse `suggested_ordered_related_items` links as `HYPERLINKS_TO`.
MATCH (p)-[:LINKS_TO {linkTargetType: 'suggested_ordered_related_items'}]->(q)
CREATE (p)-[:HYPERLINKS_TO]->(q)
;

// Reuse `ordered_related_items` links as `HYPERLINKS_TO`.
MATCH (p)-[:LINKS_TO {linkTargetType: 'ordered_related_items'}]->(q)
CREATE (p)-[:HYPERLINKS_TO]->(q)
;

// Reuse `ordered_related_items_overrides` links as `HYPERLINKS_TO`.
MATCH (p)-[:LINKS_TO {linkTargetType: 'ordered_related_items_overrides'}]->(q)
CREATE (p)-[:HYPERLINKS_TO]->(q)
;

// Reuse `suggested_ordered_related_items` links as `HAS_SUGGESTED_ORDERED_RELATED_ITEMS`.
MATCH (p)-[:LINKS_TO {linkTargetType: 'suggested_ordered_related_items'}]->(q)
CREATE (p)-[:HAS_SUGGESTED_ORDERED_RELATED_ITEMS]->(q)
;

// Reuse `ordered_child_organisations` links as `HAS_CHILD_ORGANISATION`.
MATCH (a:Organisation)-[:HAS_HOMEPAGE]->(b:Page)-[:LINKS_TO {linkTargetType: 'ordered_child_organisations'}]->(c:Page)<-[:HAS_HOMEPAGE]-(d:Organisation)
CREATE (a)-[:HAS_CHILD_ORGANISATION]->(d)
;

// Reuse `ordered_parent_organisations` links as `HAS_PARENT_ORGANISATION`.
MATCH (a:Organisation)-[:HAS_HOMEPAGE]->(b:Page)-[:LINKS_TO {linkTargetType: 'ordered_parent_organisations'}]->(c:Page)<-[:HAS_HOMEPAGE]-(d:Organisation)
CREATE (a)-[:HAS_PARENT_ORGANISATION]->(d)
;

// Reuse `ordered_successor_organisations` links as `HAS_SUPERSEDED`.
MATCH (a:Organisation)-[:HAS_HOMEPAGE]->(b:Page)-[:LINKS_TO {linkTargetType: 'ordered_successor_organisations'}]->(c)<-[:HAS_HOMEPAGE]-(d)
CREATE (a)<-[:HAS_SUPERSEDED]-(d)
;

// Reuse `organisations` links as `HAS_ORGANISATION`.
MATCH (a)-[:LINKS_TO {linkTargetType: 'organisations'}]->(b:Page)<-[:HAS_HOMEPAGE]-(c:Organisation)
CREATE (a)-[:HAS_ORGANISATIONS]->(c)
;

// Reuse `supporting_organisations` links as `HAS_SUPPORTING_ORGANISATIONS`.
MATCH (a:Page)-[:LINKS_TO {linkTargetType: 'supporting_organisations'}]->(b:Page)<-[:HAS_HOMEPAGE]-(c:Organisation)
CREATE (a)-[:HAS_SUPPORTING_ORGANISATIONS]->(c)
;

// Reuse `primary_publishing_organisation` links as `HAS_PRIMARY_PUBLISHING_ORGANISATION`.
MATCH (a:Page)-[:LINKS_TO {linkTargetType: 'primary_publishing_organisation'}]->(b:Page)<-[:HAS_HOMEPAGE]-(c:Organisation)
CREATE (a)-[:HAS_PRIMARY_PUBLISHING_ORGANISATION]->(c)
;

// Reuse `original_primary_publishing_organisation` links as `HAS_ORIGINAL_PRIMARY_PUBLISHING_ORGANISATION`.
MATCH (a:Page)-[:LINKS_TO {linkTargetType: 'original_primary_publishing_organisation'}]->(b:Page)<-[:HAS_HOMEPAGE]-(c:Organisation)
CREATE (a)-[:HAS_ORIGINAL_PRIMARY_PUBLISHING_ORGANISATION]->(c)
;

// Reuse `taxons` links as `IS_TAGGED_TO`.
MATCH (a)-[:LINKS_TO {linkTargetType: 'taxons'}]->(b)<-[:HAS_HOMEPAGE]-(c)
CREATE (a)-[:IS_TAGGED_TO]->(c)
;

// Reuse `child` links as `HAS_CHILD`.  These aren't taxons or organisations.
MATCH (a)-[:LINKS_TO {linkTargetType: 'children'}]->(b)
CREATE (a)-[:HAS_CHILD]->(b)
;

// Reuse `parent_taxons` links as `HAS_PARENT`.
MATCH (a:Taxon)-[:HAS_HOMEPAGE]->(b:Page)-[:LINKS_TO {linkTargetType: 'parent_taxons'}]->(c:Page)<-[:HAS_HOMEPAGE]-(d:Taxon)
CREATE (a)-[:HAS_PARENT]->(d)
;

MATCH (n:Page) WHERE left(n.url, 18) <> "https://www.gov.uk"
SET n:ExternalPage
REMOVE n:Page
;

// Page-to-page transitions from Google Analytics (GA4, BigQuery)
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///page_to_page_transitions_000000000000.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.from_url })
MATCH (q:Page { url: line.to_url })
CREATE (p)-[:USER_MOVEMENT{
  numberOfMovements: toInteger(line.number_of_movements),
  numberOfUserPseudoIds: toInteger(line.number_of_user_pseudo_ids),
  numberOfSessions: toInteger(line.number_of_sessions)
}]->(q)
;

// Bank holidays
CALL apoc.load.json("https://www.gov.uk/bank-holidays.json")
YIELD value
UNWIND apoc.map.sortedProperties(value) AS divisions
WITH divisions[1] AS division
WITH *, division.division AS id
CREATE (div:Division {
  url: "https://www.gov.uk/divisions/" + id,
  name: CASE id
    WHEN "england-and-wales" THEN "England and Wales"
    WHEN "northern-ireland" THEN "Northern Ireland"
    WHEN "scotland" THEN "Scotland"
    ELSE id
  END
})
WITH *
UNWIND division.events AS event
MERGE (holiday:BankHoliday {
  url: "https://www.gov.uk/bank-holidays/" + event.title,
  name: event.title
})
MERGE (date:Date {
  url: "https://www.gov.uk/dates/" + event.date,
  dateString: event.date
})
MERGE (holiday)-[:IS_OBSERVED_IN]->(div)
WITH *, CASE event.notes WHEN "" THEN NULL ELSE event.notes END AS note
MERGE (holiday)-[observance:IS_ON]->(date)
SET observance.notes = note
;

// PAGERANK
// Run weighted PageRank to identify influential Pages
// This requires some sense check and exploration to determine whether it's suited to this approach

// Firstly, create projection of Page nodes and USER_MOVEMENT relationships with their weight
CALL gds.graph.project.cypher(
'page-user-movement',
'MATCH (n:Page) RETURN id(n) as id',
'MATCH (t)-[m:USER_MOVEMENT]-(g) RETURN id(t) AS source, id(g) AS target, type(m) as type, m.numberOfMovements as weight'
);

// Calculate pagerank on the projection
CALL gds.pageRank.write('page-user-movement', {
  maxIterations: 20,
  dampingFactor: 0.85,
  writeProperty: 'pagerank',
  relationshipTypes: ['USER_MOVEMENT'],
  relationshipWeightProperty: 'weight'
})
YIELD nodePropertiesWritten, ranIterations
RETURN count(nodePropertiesWritten);

// We don't need this projection any more so drop it
CALL gds.graph.drop('page-user-movement') YIELD graphName;
