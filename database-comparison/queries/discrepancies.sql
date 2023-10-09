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
  jsonb_array_length(editions_latest.redirects) AS redirects,
  schema_name like '%placeholder%' AS placeholder,
  unpublishings.type AS unpublishing_type
from editions_latest
inner join register using (base_path)
left join unpublishings on editions_latest.id = unpublishings.edition_id
where content_mongo is null
)
select *, count(*) as n
from features
group by state, phase, content_store, redirects, placeholder, unpublishing_type
order by state, phase, content_store, redirects, placeholder, unpublishing_type
;
--     state    | phase | content_store | redirects | placeholder | unpublishing_type |  n
-- -------------+-------+---------------+-----------+-------------+-------------------+------
--  published   | live  | live          |         0 | f           |                   |  235 truly published, content store is a bit behind
--  published   | live  | live          |         0 | t           |                   | 1218
--  published   | live  | live          |         1 | f           |                   |    4
--  superseded  | live  |               |         0 | f           |                   |   30
--  superseded  | live  |               |         0 | t           |                   |  655
--  unpublished | alpha | live          |         0 | f           | vanish            |    1
--  unpublished | live  | live          |         0 | f           | vanish            |  293
--  unpublished | live  | live          |         0 | t           | vanish            |   99
--  unpublished | live  | live          |         0 | t           | withdrawal        |    1
--  unpublished | live  | live          |         1 | f           | gone              |    1
--  unpublished | live  | live          |         1 | f           | vanish            |    3

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

-- What kind of pages are in the mongo content store?
with features AS (
select
  state,
  phase,
  content_store,
  NOT jsonb_array_length(editions_latest.redirects) = 0 AS redirects,
  schema_name like '%placeholder%' AS placeholder,
  unpublishings.type AS unpublishing_type
from editions_latest
inner join register using (base_path)
left join unpublishings on editions_latest.id = unpublishings.edition_id
where content_mongo
)
select *, count(*) as n
from features
group by state, phase, content_store, redirects, placeholder, unpublishing_type
order by state, phase, content_store, redirects, placeholder, unpublishing_type
;
--     state    | phase | content_store | redirects | placeholder | unpublishing_type |   n
-- -------------+-------+---------------+-----------+-------------+-------------------+--------
--  published   | alpha | live          | f         | f           |                   |    144
--  published   | beta  | live          | f         | f           |                   |  83715
--  published   | beta  | live          | t         | f           |                   |    673
--  published   | live  | live          | f         | f           |                   | 585587
--  published   | live  | live          | f         | t           |                   |     46
--  published   | live  | live          | t         | f           |                   |  86785
--  superseded  | live  |               | f         | f           | gone              |     91
--  superseded  | live  |               | f         | f           | redirect          |   6363
--  superseded  | live  |               | f         | f           | substitute        |      3
--  superseded  | live  |               | f         | f           |                   |    163
--  superseded  | live  |               | f         | t           | gone              |      1
--  superseded  | live  |               | f         | t           | redirect          |    743
--  superseded  | live  |               | f         | t           |                   |      7
--  unpublished | alpha | live          | f         | f           | gone              |      4
--  unpublished | alpha | live          | f         | f           | redirect          |    602
--  unpublished | beta  | live          | f         | f           | redirect          |    108
--  unpublished | live  | live          | f         | f           | gone              |   4896
--  unpublished | live  | live          | f         | f           | redirect          |  68578
--  unpublished | live  | live          | f         | f           | withdrawal        |  52801
--  unpublished | live  | live          | f         | t           | gone              |    344
--  unpublished | live  | live          | f         | t           | redirect          |    821
--  unpublished | live  | live          | t         | f           | gone              |     11
--  unpublished | live  | live          | t         | f           | redirect          |    756
--  unpublished | live  |               | f         | f           | gone              |     13
--  unpublished | live  |               | f         | f           | redirect          |     95
--  unpublished | live  |               | f         | t           | gone              |      1
--  unpublished | live  |               | t         | f           | substitute        |    211

-- What pages are only in the mongo content store, not in publishing?
select base_path
from register
left join editions_latest using(base_path)
where editions_latest.base_path is null
;

-- Why are superseded pages in the mongo content store?
with features AS (
select
  base_path,
  state,
  phase,
  content_store,
  jsonb_array_length(redirects) AS redirects,
  schema_name like '%placeholder%' AS placeholder
from editions_latest
inner join register using (base_path)
)
select *
from features
where state = 'unpublished'
and phase = 'live'
and content_store = 'live'
and redirects = 0
and not placeholder
;

select * from editions_latest where base_path = '/guidance/poultry-registration';
select * from editions where base_path = '/guidance/poultry-registration' order by updated_at;
select * from editions where base_path = '/government/publications/poultry-including-game-birds-registration-rules-and-forms' order by updated_at;

-- Why are pages that in real life are redirected, in the publishing database as
-- not being redirected?
-- Because redirects can be expressed in the 'unpublishings' table instead.
select * from editions where base_path = '/growth-loans-london' order by updated_at;
select * from editions_latest where base_path = '/growth-loans-london';
