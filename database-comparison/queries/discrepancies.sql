-- Import the documents from the CSV files into the publishing database
psql -c "DROP TABLE IF EXISTS register; CREATE TABLE register (content_id uuid, locale VARCHAR, base_path VARCHAR, content_mongo integer, content_postgres integer, publishing integer);"
psql -c "\copy register FROM 'data/register-of-all-urls.csv' csv header"
psql -c "DROP TABLE IF EXISTS register_null_content_id; CREATE TABLE register_null_content_id (locale VARCHAR, base_path VARCHAR, content_mongo integer, content_postgres integer);"
psql -c "\copy register_null_content_id FROM 'data/register-of-null-content-ids.csv' csv header"

-- 1. What kind of pages are in each database
-- 2. How many of each kind are in the publishing database
-- 3. Relatively, how many more or fewer are in the content_mongo database
-- 4. Relative to the content_mongo database, how many more or fewer are in the
--    content_postgres database
--
-- Examples:
--
-- - Suppose there are 5 docs of a certain kind in the publishing database, and
--   relative to that there are minus 5 of the same kind in the content_mongo
--   database, then that means that there are none of that kind in the
--   content_mongo database.
--
-- - Suppose there are 10 docs of a certain kind in the publishing database, and
--   relative to that there are 0 of the same kind in the content_mongo
--   database, then that means that all 10 are in the content_mongo database.
--
-- - Suppose there are 20 docs of a certain kind in the publishing database, and
--   relative to that there are minus 19 of the same kind in the content_mongo
--   database, then that means that there is one of that kind in the
--   content_mongo database.  I have checked all such discrepancies, and they
--   aren't logically resolvable, they are mistakes in the data.
--
-- - The numbers for the content_postgres database are relative to the
--   content_mongo database, and are assumed to be nonzero because the
--   content_postgres backup was about a day after the content_mongo one.
DROP TABLE IF EXISTS features;
CREATE TABLE features AS (
-- Gather some metadata from the publishing database
with metadata AS (
    -- Match the register on content_id and locale
    select
      editions_latest.id AS edition_id,
      editions_latest.content_id,
      editions_latest.locale,
      editions_latest.base_path,
      schema_name,
      state,
      content_store,
      publishing,
      content_mongo,
      content_postgres
    from register
    inner join editions_latest on true
    and register.locale = editions_latest.locale
    and register.content_id = editions_latest.content_id
  union all
    -- Match on base_path, rather than content_id and locale, because
    -- some docs don't have a content_id, because they have been unpublished as a
    -- 'redirect' or a 'gone' 410 error, which apply to the URL rather than to
    -- the document.
    --
    -- Examples in the postgres content store:
    --
    --     select document_type, count(*)
    --     from content_items
    --     where content_id is null
    --     group by document_type;
    --
    --  document_type | count
    -- ---------------+-------
    --                |     5
    --  redirect      | 80736
    --  gone          |  5343
    --
    -- Some editions will match multiple documents, because a base_path of an
    -- unpublished document can be re-used by a new document, and if that new
    -- document is also unpublished and is stripped of its content_id, then
    -- there is no way (without referring to timestamps) to tell which edition
    -- is the true match (the edition of the original document, or the one of
    -- the later document). This is handled later by counting a maximum of one
    -- match per edition.
  select
      editions_latest.id AS edition_id,
      editions_latest.content_id,
      editions_latest.locale,
      editions_latest.base_path,
      schema_name,
      state,
      content_store,
      publishing,
      content_mongo,
      content_postgres
    from register
    inner join editions_latest on true
    and editions_latest.content_store = 'live'
    and register.content_id is null
    and register.base_path = editions_latest.base_path
),
merged as (
  -- There are some duplicates, because a base_path of an unpublished document
  -- can be re-used by a new document, and if that new document is also
  -- unpublished and is stripped of its content_id, then there is no way
  -- (without referring to timestamps) to tell which edition is the true match
  -- (the edition of the original document, or the one of the later document).
  -- This is handled by counting a maximum of one match per edition.
  select
    edition_id,
    content_id,
    locale,
    base_path,
    schema_name,
    state,
    content_store,
    max(publishing) as publishing,
    max(content_mongo) as content_mongo,
    max(content_postgres) as content_postgres
  from metadata
  group by
    edition_id,
    content_id,
    locale,
    base_path,
    schema_name,
    state,
    content_store
)
select
  merged.edition_id,
  content_id,
  locale,
  base_path,
  unpublishings.type AS unpublishing_type,
  schema_name like '%placeholder%' AS placeholder,
  state, content_store,
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
  content_store,
  state,
  base_path is not null AS has_base_path,
  placeholder,
  unpublishing_type,
  coalesce(sum(publishing), 0) as publishing,
  coalesce(sum(content_mongo), 0) - coalesce(sum(publishing), 0) as content_mongo_diff,
  coalesce(sum(content_postgres), 0) - coalesce(sum(content_mongo), 0) as content_postgres_diff
from features
group by content_store, state, placeholder, has_base_path, unpublishing_type
order by content_store, state, placeholder, has_base_path desc, unpublishing_type
)
;
\copy feature_counts TO 'data/feature_counts.csv' csv header;
select *
from feature_counts
;

--  content_store |    state    | has_base_path | placeholder | unpublishing_type | publishing | content_mongo_diff | content_postgres_diff
-- ---------------+-------------+---------------+-------------+-------------------+------------+--------------------+-----------------------
--  live          | published   | t             | f           |                   |     757477 |               -241 |                 -3863
--  live          | published   | f             | f           |                   |      15509 |             -15509 |                     0
--  live          | published   | t             | t           |                   |       1264 |              -1218 |                   -10
--  live          | unpublished | t             | f           | gone              |       4912 |                 -1 |                    -5
--  live          | unpublished | t             | f           | redirect          |      70045 |                  0 |                   -11
--  live          | unpublished | t             | f           | vanish            |        297 |               -297 |                     0
--  live          | unpublished | t             | f           | withdrawal        |      52801 |                  0 |                   -22
--  live          | unpublished | f             | f           | gone              |       1293 |              -1293 |                     0
--  live          | unpublished | t             | t           | gone              |        344 |                  0 |                     0
--  live          | unpublished | t             | t           | redirect          |        821 |                  0 |                     0
--  live          | unpublished | t             | t           | vanish            |         99 |                -99 |                     0
--  live          | unpublished | t             | t           | withdrawal        |          1 |                 -1 |                     0
--                | superseded  | t             | f           | redirect          |          3 |                 -3 |                     0
--                | superseded  | t             | f           |                   |         15 |                -13 |                     0
--                | superseded  | t             | t           |                   |         24 |                -24 |                     0
--                | unpublished | t             | f           | gone              |         13 |                -13 |                     0
--                | unpublished | t             | f           | redirect          |         95 |                -95 |                     0
--                | unpublished | t             | f           | substitute        |       7725 |              -7725 |                     6
--                | unpublished | t             | t           | gone              |          1 |                 -1 |                     0
--                | unpublished | t             | t           | substitute        |         86 |                -86 |                     0

-- Content store if:
-- content_store = 'live'
-- -- Nothing is both 'live' and 'superseded' to test whether 'superseded' is
-- -- worth checking. I think we ought to check it anyway, going by the
-- -- documentation.
-- and state<>'superseded'
-- and coalesce(unpublishing.type <> 'vanish', true)
-- and (not placeholder or (placeholder and coalesce(unpublishing.type in ('gone', 'redirect'), false)))
-- -- Without a base_path, it isn't a document in the content store in its own
-- -- right, but if all the other criteria pass then it can be an expanded link
-- -- such as a 'contact' or a 'role' or 'role_appointment'
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
-- If you switch has_base_path to has_not_base_path, then those are 'contact',
-- 'role' and other documents that are in the content store as expanded links,
-- but not as pages in their own right.
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

-- Query for the types of docs that are usually in the content store as expanded
-- links only, not in their own right.  Some "role" docs are in the content
-- store in their own right, and those ones have a base_path.
select schema_name, count(*)
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
and base_path is null
group by schema_name
;
--    schema_name    | count
-- ------------------+-------
--  contact          |  3910
--  external_content |   595
--  facet            |     9
--  facet_group      |     2
--  facet_value      |    95
--  role             |  3938
--  role_appointment |  8024
--  world_location   |   229

-- external_content goes to the search API so that search results can include
-- other websites, such as police.gov.uk.
select * from editions_latest where schema_name = 'external_content';

-- In the content store, unpublishings of type 'redirect' and 'gone' are
-- present, but without a content_id, even though they do have a content_id in
-- the publishing database.
--   select document_type, count(*)
--   from content_items
--   where content_id is null
--   group by document_type
--   ;
--  document_type | count
-- ---------------+-------
--                |     5
--  redirect      | 80736
--  gone          |  5343
