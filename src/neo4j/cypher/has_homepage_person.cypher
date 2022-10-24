MATCH (p:Page { documentType: 'person' })
CREATE (q:Person {
  url: 'https://www.gov.uk/' + p.contentId,
  name: p.title,
  contentId: p.contentId
})
CREATE (q)-[:HAS_HOMEPAGE]->(p)
;
