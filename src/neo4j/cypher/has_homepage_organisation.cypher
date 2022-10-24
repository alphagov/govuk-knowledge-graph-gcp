// Organisations, persons, and taxons
MATCH (p:Page { documentType: 'organisation' })
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
