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
