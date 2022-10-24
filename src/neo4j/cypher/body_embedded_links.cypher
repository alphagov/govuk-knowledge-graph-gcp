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
