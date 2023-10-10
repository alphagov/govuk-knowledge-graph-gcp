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
psql -c "DROP TABLE IF EXISTS register; CREATE TABLE register (base_path VARCHAR, content_mongo integer, content_postgres integer, publishing integer);"
psql -c "\copy register FROM 'data/register-of-all-urls.csv' csv header"

-- What kind of pages are in each database?
DROP TABLE IF EXISTS features;
CREATE TABLE features AS (
with features AS (
select
  unpublishings.type AS unpublishing_type,
  schema_name like '%placeholder%' AS placeholder,
  state,
  phase,
  content_store,
  NOT jsonb_array_length(editions_latest.redirects) = 0 AS redirects,
  publishing,
  content_mongo,
  content_postgres
from register
left join editions_latest using (base_path)
left join unpublishings on editions_latest.id = unpublishings.edition_id
)
select
  unpublishing_type, placeholder, state, phase, content_store, redirects,
  coalesce(sum(publishing), 0) as publishing,
  coalesce(sum(content_mongo), 0) - coalesce(sum(publishing), 0) as content_mongo_diff,
  coalesce(sum(content_postgres), 0) - coalesce(sum(content_mongo), 0) as content_postgres_diff
from features
group by unpublishing_type, placeholder, state, phase, content_store, redirects
order by unpublishing_type, placeholder, state, phase, content_store, redirects
)
;
select * from features;

--     state    | phase | content_store | redirects | placeholder | unpublishing_type | publishing | content_mongo_diff | content_postgres_diff
-- -------------+-------+---------------+-----------+-------------+-------------------+------------+--------------------+-----------------------
--  published   | alpha | live          | f         | f           |                   |        144 |                  0 |                     0
--  published   | beta  | live          | f         | f           |                   |      83715 |                  0 |                   -47
--  published   | beta  | live          | t         | f           |                   |        673 |                  0 |                     0
--  published   | live  | live          | f         | f           |                   |     585822 |               -235 |                 -3789
--  published   | live  | live          | f         | t           |                   |       1264 |              -1218 |                   -10
--  published   | live  | live          | t         | f           |                   |      86789 |                 -4 |                   -22
--  superseded  | live  |               | f         | f           | gone              |         91 |                  0 |                     0
--  superseded  | live  |               | f         | f           | redirect          |       6363 |                  0 |                     0
--  superseded  | live  |               | f         | f           | substitute        |          3 |                  0 |                     0
--  superseded  | live  |               | f         | f           |                   |        193 |                -30 |                     0
--  superseded  | live  |               | f         | t           | gone              |          1 |                  0 |                     0
--  superseded  | live  |               | f         | t           | redirect          |        743 |                  0 |                     0
--  superseded  | live  |               | f         | t           |                   |        662 |               -655 |                     0
--  unpublished | alpha | live          | f         | f           | gone              |          4 |                  0 |                     0
--  unpublished | alpha | live          | f         | f           | redirect          |        602 |                  0 |                     0
--  unpublished | alpha | live          | f         | f           | vanish            |          1 |                 -1 |                     0
--  unpublished | beta  | live          | f         | f           | redirect          |        108 |                  0 |                     0
--  unpublished | live  | live          | f         | f           | gone              |       4896 |                  0 |                    -3
--  unpublished | live  | live          | f         | f           | redirect          |      68578 |                  0 |                   -11
--  unpublished | live  | live          | f         | f           | vanish            |        293 |               -293 |                     0
--  unpublished | live  | live          | f         | f           | withdrawal        |      52801 |                  0 |                   -22
--  unpublished | live  | live          | f         | t           | gone              |        344 |                  0 |                     0
--  unpublished | live  | live          | f         | t           | redirect          |        821 |                  0 |                     0
--  unpublished | live  | live          | f         | t           | vanish            |         99 |                -99 |                     0
--  unpublished | live  | live          | f         | t           | withdrawal        |          1 |                 -1 |                     0
--  unpublished | live  | live          | t         | f           | gone              |         12 |                 -1 |                    -2
--  unpublished | live  | live          | t         | f           | redirect          |        756 |                  0 |                     0
--  unpublished | live  | live          | t         | f           | vanish            |          3 |                 -3 |                     0
--  unpublished | live  |               | f         | f           | gone              |         13 |                  0 |                     0
--  unpublished | live  |               | f         | f           | redirect          |         95 |                  0 |                     0
--  unpublished | live  |               | f         | t           | gone              |          1 |                  0 |                     0
--  unpublished | live  |               | t         | f           | substitute        |        211 |                  0 |                     0
--              |       |               |           |             |                   |          0 |                 36 |                   -12
