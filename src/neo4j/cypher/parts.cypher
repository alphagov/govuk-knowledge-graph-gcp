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
