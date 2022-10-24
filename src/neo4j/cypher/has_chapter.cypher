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
