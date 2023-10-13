-- Discrepancies between tables
SELECT * EXCLUDE (content_id, locale, base_path), count(*) AS n
FROM register
GROUP BY *
ORDER BY * EXCLUDE (content_id, locale, base_path)
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

-- ┌───────────────┬──────────────────┬────────────┬────────┐
-- │ content_mongo │ content_postgres │ publishing │   n    │
-- │     int32     │      int32       │   int32    │ int64  │
-- ├───────────────┼──────────────────┼────────────┼────────┤
-- │             1 │                1 │          1 │ 802839 │ happy path
-- │             1 │                1 │            │  86119 │ ?
-- │             1 │                  │          1 │   3881 │ content_postgres is a day behind
-- │             1 │                  │            │    759 │ ?
-- │               │                1 │          1 │    656 │ ?
-- │               │                1 │            │     66 │ ?
-- │               │                  │          1 │ 105449 │ ?
-- └───────────────┴──────────────────┴────────────┴────────┘

-- Import the documents from the CSV files into the publishing database
psql -c "DROP TABLE IF EXISTS register; CREATE TABLE register (content_id uuid, locale VARCHAR, base_path VARCHAR, content_mongo integer, content_postgres integer, publishing integer);"
psql -c "\copy register FROM 'data/register-of-all-urls.csv' csv header"
psql -c "DROP TABLE IF EXISTS register_null_content_id; CREATE TABLE register_null_content_id (locale VARCHAR, base_path VARCHAR, content_mongo integer, content_postgres integer);"
psql -c "\copy register_null_content_id FROM 'data/register-of-null-content-ids.csv' csv header"

-- What kind of pages are in each database?
DROP TABLE IF EXISTS features;
CREATE TABLE features AS (
with content_stores AS (
    select
      editions_latest.id AS edition_id,
      editions_latest.content_id,
      editions_latest.locale,
      editions_latest.base_path,
      schema_name,
      state,
      phase,
      content_store,
      editions_latest.redirects,
      document_type,
      publishing,
      content_mongo,
      content_postgres
    from register
    inner join editions_latest on
    register.locale = editions_latest.locale
    and register.content_id = editions_latest.content_id
  union all
    select
      editions_latest.id AS edition_id,
      editions_latest.content_id,
      editions_latest.locale,
      editions_latest.base_path,
      schema_name,
      state,
      phase,
      content_store,
      editions_latest.redirects,
      document_type,
      publishing,
      content_mongo,
      content_postgres
    from register
    inner join editions_latest on
    register.locale = editions_latest.locale
    and editions_latest.content_store = 'live'
    and register.content_id is null
    and register.base_path = editions_latest.base_path
),
publishing AS (
  select
    editions_latest.id AS edition_id,
    editions_latest.content_id,
    editions_latest.locale,
    editions_latest.base_path,
    editions_latest.schema_name,
    editions_latest.state,
    editions_latest.phase,
    editions_latest.content_store,
    editions_latest.redirects,
    editions_latest.document_type,
    0 as publishing,
    0 as content_mongo,
    0 as content_postgres
  from editions_latest
  left join content_stores on content_stores.edition_id = editions_latest.id
  where content_stores.edition_id is null
),
all_three as (
  select * from content_stores
  union all
  select * from publishing
),
merged as (
  select
    edition_id,
    content_id,
    locale,
    base_path,
    schema_name,
    state,
    phase,
    content_store,
    redirects,
    document_type,
    max(publishing) as publishing,
    max(content_mongo) as content_mongo,
    max(content_postgres) as content_postgres
  from all_three
  group by
    edition_id,
    content_id,
    locale,
    base_path,
    schema_name,
    state,
    phase,
    content_store,
    redirects,
    document_type
)
select
  merged.edition_id,
  content_id,
  locale,
  base_path,
  unpublishings.type AS unpublishing_type,
  schema_name like '%placeholder%' AS placeholder,
  state, phase, content_store,
  NOT jsonb_array_length(merged.redirects) = 0 AS has_redirects,
  document_type = 'redirect' AS is_redirect,
  publishing,
  content_mongo,
  content_postgres
from merged
left join unpublishings on merged.edition_id = unpublishings.edition_id
)
;
\copy features TO 'data/features.csv' csv header;
DROP TABLE IF EXISTS feature_counts;
CREATE TABLE feature_counts AS (
select
  unpublishing_type,
  placeholder,
  state,
  phase,
  content_store,
  has_redirects,
  is_redirect,
  base_path is not null AS has_base_path,
  coalesce(sum(publishing), 0) as publishing,
  coalesce(sum(content_mongo), 0) - coalesce(sum(publishing), 0) as content_mongo_diff,
  coalesce(sum(content_postgres), 0) - coalesce(sum(content_mongo), 0) as content_postgres_diff
from features
group by unpublishing_type, placeholder, state, phase, content_store, has_redirects, is_redirect, has_base_path
order by unpublishing_type, placeholder, state, phase, content_store, has_redirects, is_redirect, has_base_path
)
;
\copy feature_counts TO 'data/feature_counts.csv' csv header;
select * from feature_counts;

🆗
--  unpublishing_type | placeholder |    state    | phase | content_store | has_redirects | is_redirect | has_base_path | publishing | content_mongo_diff | content_postgres_diff
-- -------------------+-------------+-------------+-------+---------------+---------------+-------------+---------------+------------+--------------------+-----------------------

--  gone              | f           | unpublished | alpha | live          | f             | f           | t             |          4 |                  0 |                     0
--  gone              | f           | unpublished | live  | live          | f             | f           | t             |       4896 |                  0 |                    -3
--  gone              | t           | unpublished | live  | live          | f             | f           | t             |        344 |                  0 |                     0
--  gone              | f           | unpublished | live  | live          | t             | t           | t             |         12 |                 -1 |                    -2
--  redirect          | f           | unpublished | alpha | live          | f             | f           | t             |        602 |                  0 |                     0
--  redirect          | f           | unpublished | beta  | live          | f             | f           | t             |        108 |                  0 |                     0
--  redirect          | f           | unpublished | live  | live          | f             | f           | t             |      68579 |                  0 |                   -11
--  redirect          | f           | unpublished | live  | live          | t             | t           | t             |        756 |                  0 |                     0
--  redirect          | t           | unpublished | live  | live          | f             | f           | t             |        821 |                  0 |                     0
--                    | f           | published   | alpha | live          | f             | f           | t             |        144 |                  0 |                     0
--                    | f           | published   | beta  | live          | f             | f           | t             |      83715 |                  0 |                   -47
--                    | f           | published   | beta  | live          | t             | t           | t             |        673 |                  0 |                     0
--  withdrawal        | f           | unpublished | live  | live          | f             | f           | t             |      52801 |                  0 |                   -22
--                    | f           | published   | live  | live          | f             | f           | t             |     585822 |               -233 |                 -3734
--                    | f           | published   | live  | live          | t             | t           | t             |      87123 |                 -8 |                   -82

--  gone              | f           | unpublished | live  | live          | f             | f           | f             |       1293 |              -1293 |                     0
--  gone              | f           | unpublished | live  |               | f             | f           | t             |         13 |                -13 |                     0
--  gone              | t           | unpublished | live  |               | f             | f           | t             |          1 |                 -1 |                     0
--  redirect          | f           | superseded  | live  |               | f             | f           | t             |          3 |                 -3 |                     0
--  redirect          | f           | unpublished | live  |               | f             | f           | t             |         95 |                -95 |                     0
--  substitute        | f           | unpublished | alpha |               | f             | f           | t             |          1 |                 -1 |                     0
--  substitute        | f           | unpublished | beta  |               | f             | f           | t             |          1 |                 -1 |                     0
--  substitute        | f           | unpublished | live  |               | f             | f           | t             |       6029 |              -6029 |                     0
--  substitute        | f           | unpublished | live  |               | t             | t           | t             |       1694 |              -1694 |                     6
--  substitute        | t           | unpublished | live  |               | f             | f           | t             |         86 |                -86 |                     0
--  vanish            | f           | unpublished | alpha | live          | f             | f           | t             |          1 |                 -1 |                     0
--  vanish            | f           | unpublished | live  | live          | f             | f           | t             |        293 |               -293 |                     0
--  vanish            | f           | unpublished | live  | live          | t             | t           | t             |          3 |                 -3 |                     0
--  vanish            | t           | unpublished | live  | live          | f             | f           | t             |         99 |                -99 |                     0
--  withdrawal        | t           | unpublished | live  | live          | f             | f           | t             |          1 |                 -1 |                     0
--                    | f           | published   | live  | live          | f             | f           | f             |      15509 |             -15509 |                     0
--                    | f           | superseded  | live  |               | f             | f           | t             |         15 |                -13 |                     0
--                    | t           | published   | live  | live          | f             | f           | t             |       1264 |              -1218 |                   -10
--                    | t           | superseded  | live  |               | f             | f           | t             |         24 |                -24 |                     0

-- Content store if:
-- content_store = 'live'
-- -- Nothing is both 'live' and 'superseded' to test whether 'superseded' is
-- -- worth checking. I think we ought to check it anyway, going by the
-- -- documentation.
-- and state<>'superseded'
-- and coalesce(unpublishing.type <> 'vanish', true)
-- and (not placeholder or (placeholder and coalesce(unpublishing.type in ('gone', 'redirect'), false)))
-- and has_base_path

-- placeholder | unpublishing  | in_content_store
-- ------------|---------------|-----------------
-- f           | gone/redirect | t
-- f           | other         | t
-- f           | null          | t
-- t           | gone/redirect | t
-- t           | other         | f
-- t           | null          | f

-- Query for which docs are in the content store as docs in their own right
select count(*)
from editions_latest
left join unpublishings on unpublishings.edition_id = editions_latest.id
where true
and content_store = 'live'
and state <> 'superseded'
and coalesce(unpublishings.type <> 'vanish', true)
and (
  left(schema_name, 11) <> 'placeholder'
  or (
    left(schema_name, 11) = 'placeholder'
    and coalesce(unpublishings.type in ('gone', 'redirect'), false)
  )
)
and base_path is not null
;

-- I currently believe that if you switch has_base_path to has_not_base_path,
-- then those are 'contact', 'role' and other documents that are in the content
-- store as expanded links, but not as pages in their own right.

-- In the content store, unpublishings of type 'redirect' and 'gone' are
-- present, but without a content_id.
-- content_store_test_deleteme=# select document_type, count(*) from content_items where content_id is null group by document_type;
--  document_type | count
-- ---------------+-------
--                |     5
--  redirect      | 80736
--  gone          |  5343

-- 1. an edition of document_type:coming_soon, with a base_path
-- 2. that edition is unpublished type:substitute, with no redirect
-- 3. maybe an edition of a different document_id, document_type:national_statistics
--
-- If step 3 doesn't happen then the edition is absent from the content store
--
-- If step 3 does happen then the edition seems present in the content store,
-- because there is a match on base_path, but in fact a different edition is the
-- correct match.

-- The 87123 that have -8 in content_mongo
select editions.updated_at, features.*
from features
left join editions on editions.id = features.edition_id
where true
and unpublishing_type is null
and not placeholder
and features.state = 'published'
and features.phase = 'live'
and features.content_store = 'live'
and has_redirects
and is_redirect
and content_mongo is null
order by editions.updated_at
;

--  unpublishing_type | placeholder |    state    | phase | content_store | has_redirects | is_redirect | has_base_path | publishing | content_mongo_diff | content_postgres_diff
-- -------------------+-------------+-------------+-------+---------------+---------------+-------------+---------------+------------+--------------------+-----------------------
--                    | f           | published   | live  | live          | t             | t           | t             |      87123 |                 -8 |                   -82

-- One example 6f5d09ff-0df4-409a-b4fe-b9d6b53e5360 /government/publications/quality-information-to-accompany-our-statistical-releases/7047179
-- The redirect works in the browser, but seems to be missing from the content
-- store. It was well before the database backup was created, and is still
-- missing from the current content store.
select
  documents.content_id,
  unpublishings.type AS unpublishing_type,
  unpublishings.redirects AS unpublishing_redirects,
  editions.*
from editions
inner join documents ON documents.id = editions.document_id
left join unpublishings on unpublishings.edition_id = editions.id
-- where editions.base_path = '/government/publications/quality-information-to-accompany-our-statistical-releases/7047179'
where documents.content_id = '6f5d09ff-0df4-409a-b4fe-b9d6b53e5360'
or documents.content_id = 'f9beb899-7d9d-4f19-910e-0ae806adf41d'
order by updated_at
;

-- Another example
-- ab6fe4ea-56bb-4aa5-896f-dc8017f8ed98
-- /dfid-research-outputs/in-silico-and-molecular-approaches-for-associating-candidate-defense-genes-with-quantitative-resistance-to-rice-blast
-- It is in the content store with a different content_id, which is associated
-- with a different URL in the publishing database
-- 60887837-4144-4f41-8a10-80c74f57cf42
-- /research-for-development-outputs/in-silico-and-molecular-approaches-for-associating-candidate-defense-genes-with-quantitative-resistance-to-rice-blast

select editions.updated_at, features.*
from features
left join editions on editions.id = features.edition_id
where content_id = '60887837-4144-4f41-8a10-80c74f57cf42'
or content_id = 'ab6fe4ea-56bb-4aa5-896f-dc8017f8ed98'
or features.base_path = '/dfid-research-outputs/in-silico-and-molecular-approaches-for-associating-candidate-defense-genes-with-quantitative-resistance-to-rice-blast'
or features.base_path = '/research-for-development-outputs/in-silico-and-molecular-approaches-for-associating-candidate-defense-genes-with-quantitative-resistance-to-rice-blast'
order by editions.updated_at, publishing, content_mongo, content_postgres, edition_id
;

-- Check the postgres content store.  No locale.  Not my problem.
select
  base_path,
  content_id,
  details->>'locale' AS locale
from content_items where content_id = '60887837-4144-4f41-8a10-80c74f57cf42';

-- The 15 that have -13 in content_mongo
select editions.updated_at, features.*
from features
left join editions on editions.id = features.edition_id
where true
and unpublishing_type is null
and not placeholder
and features.state = 'superseded'
and features.phase = 'live'
and features.content_store is null
and not has_redirects
and not is_redirect
and content_mongo is not null
order by editions.updated_at
;

--  unpublishing_type | placeholder |    state    | phase | content_store | has_redirects | is_redirect | has_base_path | publishing | content_mongo_diff | content_postgres_diff
-- -------------------+-------------+-------------+-------+---------------+---------------+-------------+---------------+------------+--------------------+-----------------------
--                    | f           | superseded  | live  |               | f             | f           | t             |         15 |                -13 |                     0

--              content_id              | locale |                                              base_path
-- -------------------------------------+--------+----------------------------------------------------------------------------------------------------
-- 34cef73d-d1b4-4481-b541-c163cb7df737 | en     | /international-development-funding/spring-assets-to-adolescent-girls-initiative
-- 886d3b80-445a-4d09-bf53-1f95b8189e2f | en     | /international-development-funding/technology-provider-window-for-frontier-technology-livestreaming

-- 34cef73d-d1b4-4481-b541-c163cb7df737 has a different content_id in the
-- contents store 75d8cad7-98a2-4a34-b6f9-a1af26cd88d6.  That content_id doesn't
-- exist in the publishing database.
select *
from documents
where content_id = '75d8cad7-98a2-4a34-b6f9-a1af26cd88d6'
;
-- The other is similar, the content_id in the content store doesn't exist in
-- the publishing database.
select *
from documents
where content_id = '3dcc7465-598e-44bf-9531-1b9f3d310c87'
;

-- The 1264 that have 1218 in content_mongo
select editions.updated_at, features.*
from features
left join editions on editions.id = features.edition_id
where true
and unpublishing_type is null
and placeholder
and features.state = 'published'
and features.phase = 'live'
and features.content_store = 'live'
and not has_redirects
and not is_redirect
and content_mongo is not null
order by editions.updated_at
;

--  unpublishing_type | placeholder |    state    | phase | content_store | has_redirects | is_redirect | has_base_path | publishing | content_mongo_diff | content_postgres_diff
-- -------------------+-------------+-------------+-------+---------------+---------------+-------------+---------------+------------+--------------------+-----------------------
--                    | t           | published   | live  | live          | f             | f           | t             |       1264 |              -1218 |                   -10

-- 7e9f4af9-e9fa-4326-9d6b-532b3b3ce2a1 /world/organisations/uk-science-innovation-network-in-croatia/about/about

-- We can use fewer features to predict presence in each database
DROP TABLE IF EXISTS simple_features;
CREATE TABLE simple_features AS (
with simple_features AS (
select
  CASE
    WHEN unpublishings.type IS NULL THEN NULL
    WHEN unpublishings.type = 'vanish' THEN 'vanish'
    ELSE 'not vanish'
  END AS unpublishing_type,
  CASE
    WHEN unpublishings.type IS NOT NULL THEN NULL
    ELSE  schema_name like '%placeholder%'
  END AS placeholder,
  publishing,
  content_mongo,
  content_postgres
from register
left join editions_latest using (base_path)
left join unpublishings on editions_latest.id = unpublishings.edition_id
)
select
  unpublishing_type, placeholder,
  coalesce(sum(publishing), 0) as publishing,
  coalesce(sum(content_mongo), 0) - coalesce(sum(publishing), 0) as content_mongo_diff,
  coalesce(sum(content_postgres), 0) - coalesce(sum(content_mongo), 0) as content_postgres_diff
from simple_features
group by unpublishing_type, placeholder
order by unpublishing_type, placeholder
)
;
\copy simple_features TO 'data/simple_features.csv' csv header;
select * from simple_features;

-- Look at some remaining discrepancies
psql -c "DROP TABLE IF EXISTS url_content_mongo; CREATE TABLE url_content_mongo (_id VARCHAR);"
psql -c "\copy url_content_mongo FROM 'data/all-urls-content-mongo.csv' csv header"

-- Absolutely no reason why
-- https://www.gov.uk/api/content/government/topics/national-security is in the
-- content store.  It redirects, but that isn't specified anywhere.
-- https://www.gov.uk/api/content/world/organisations/uk-science-innovation-network-in-croatia/about/about
-- is in the content store, but is a 404
select
  editions_latest.base_path,
  editions_latest.updated_at,
  editions_latest.redirects
from editions_latest
inner join url_content_mongo on url_content_mongo._id = editions_latest.base_path
left join unpublishings on editions_latest.id = unpublishings.edition_id
WHERE unpublishings.edition_id IS NULL
AND  editions_latest.schema_name like '%placeholder%'
ORDER BY editions_latest.updated_at DESC
;

-- What are the different kinds of redirects?
