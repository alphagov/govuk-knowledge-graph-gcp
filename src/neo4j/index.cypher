CREATE FULLTEXT INDEX title IF NOT EXISTS
FOR (n:Page)
ON EACH [n.title]
OPTIONS {
  indexConfig: {
    `fulltext.analyzer`: 'english',
    `fulltext.eventually_consistent`: false
  }
}
;

CREATE FULLTEXT INDEX description IF NOT EXISTS
FOR (n:Page)
ON EACH [n.description]
OPTIONS {
  indexConfig: {
    `fulltext.analyzer`: 'english',
    `fulltext.eventually_consistent`: false
  }
}
;

CREATE FULLTEXT INDEX text IF NOT EXISTS
FOR (n:Page)
ON EACH [n.text]
OPTIONS {
  indexConfig: {
    `fulltext.analyzer`: 'english',
    `fulltext.eventually_consistent`: false
  }
}
;

CREATE FULLTEXT INDEX title_description_text IF NOT EXISTS
FOR (n:Page)
ON EACH [n.title, n.description, n.text]
OPTIONS {
  indexConfig: {
    `fulltext.analyzer`: 'english',
    `fulltext.eventually_consistent`: false
  }
}
;

CREATE FULLTEXT INDEX description_text IF NOT EXISTS
FOR (n:Page)
ON EACH [n.description, n.text]
OPTIONS {
  indexConfig: {
    `fulltext.analyzer`: 'english',
    `fulltext.eventually_consistent`: false
  }
}
;
