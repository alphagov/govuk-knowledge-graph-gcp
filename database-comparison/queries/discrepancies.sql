-- Discrepancies between tables
SELECT * EXCLUDE (base_path), count(*) AS n
FROM register
GROUP BY *
ORDER BY * EXCLUDE (base_path)
;
-- ┌───────────────┬──────────────────┬────────────┬────────┐
-- │ content_mongo │ content_postgres │ publishing │   n    │
-- │    boolean    │     boolean      │  boolean   │ int64  │
-- ├───────────────┼──────────────────┼────────────┼────────┤
-- │ true          │ true             │ true       │ 889669 │ happy path
-- │ true          │ true             │            │     10 │ ?
-- │ true          │                  │ true       │   3907 │ content_postgres is a day behind
-- │ true          │                  │            │     12 │ ?
-- │               │ true             │ true       │      1 │ ?
-- │               │                  │ true       │  66396 │ mainly draft
-- └───────────────┴──────────────────┴────────────┴────────┘

-- Import the URLs form the CSV file into the publishing database
psql -c "DROP TABLE IF EXISTS register; CREATE TABLE register (base_path VARCHAR, content_mongo BOOL, content_postgres BOOL, publishing BOOL);"
psql -c "\copy register FROM 'data/register-of-all-urls.csv' csv header"

-- What kind of pages are in the publishing database but not the mongo content
-- store?
with features AS (
select
  state,
  phase,
  content_store,
  jsonb_array_length(redirects) AS redirects,
  schema_name like '%placeholder%' AS placeholder
from editions_latest
inner join register using (base_path)
where content_mongo is null
)
select *, count(*) as n
from features
group by state, phase, content_store, redirects, placeholder
order by state, phase, content_store, redirects, placeholder
;

--     state    | phase | content_store | redirects | placeholder |   n
-- -------------+-------+---------------+-----------+-------------+-------
--  draft       | alpha | draft         |         0 | f           |    11
--  draft       | beta  | draft         |         0 | f           |    10
--  draft       | live  | draft         |         0 | f           | 21161
--  draft       | live  | draft         |         0 | t           |  1023
--  draft       | live  | draft         |         1 | f           | 42943
--  draft       | live  | draft         |         2 | f           |     1
--  published   | live  | live          |         0 | f           |   233 truly published, content store is a bit behind
--  published   | live  | live          |         0 | t           |   683
--  published   | live  | live          |         1 | f           |     4
--  superseded  | live  |               |         0 | t           |    23
--  unpublished | alpha | live          |         0 | f           |     1
--  unpublished | live  | live          |         0 | f           |   286
--  unpublished | live  | live          |         0 | t           |   100
--  unpublished | live  | live          |         1 | f           |     4
--  unpublished | live  |               |         0 | f           |    22

-- What "live" pages are in the publishing database but not the mongo content
-- store?
select updated_at, redirects, editions_latest.base_path
from editions_latest
inner join register using (base_path)
where
  register.publishing
  and content_mongo is null
  and state = 'published'
  and phase = 'live'
  and content_store = 'live'
  and jsonb_array_length(redirects) = 0
  and not schema_name like '%placeholder%'
order by updated_at desc
;
