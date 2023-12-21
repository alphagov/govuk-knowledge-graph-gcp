-- Update two tables with new editions.
--
-- * editions_current: the most recent edition of each document
-- * editions_online: current editions that are visible online
--
-- An edition is visible online if there is a URL where that particular document
-- is available in its own right.  Documents may also be visible as part of
-- another document, but that does not count as being 'visible online' in this
-- context.
--
-- This doesn't cost anything like as much as the estimates. Costs are lowered
-- by:
--
-- * Partitioning large tables on updated_at
-- * Subsetting for new editions before doing anything else.

-- Editions vs documents
--
-- A content item (a 'piece of content') is purely conceptual. It doesn't
-- necessarily map to a particular web page. It may represent an organisation, a
-- person, a role, a set of contact details such as addresses and telephone
-- numbers.  It also isn't versioned.  In the publishing database, it is
-- represented only by its content_id.  It doesn't even have a 'type'.  There is
-- no `content` table, because its only column would be its primary key:
-- `content_id`.
--
-- Each content item (key: content_id) has one or more documents (key:
  -- content_id, locale).  A piece of content has at most one document per
-- locale.
--
-- One document has one or more editions (key: document_id, updated_at).  The
-- edition has a `document_type`, which describes what the edition's content
-- item represents.  It is an odd name, and an odd place to record it.  The fact
-- that the `document_type` belongs to the edition rather than to either the
-- document or the content item means that the schema doesn't guarantee any of
-- the following:
--
-- * that every edition of the same content item has the same document_type
-- * that every edition of the same document has the same document_type
-- * that every _current_ edition of the same content item or document has the
-- same document_type
--
-- We must allow for the `document_type` to vary between:
--
-- * different editions of a document, which means the document_type of an
-- edition can change over time
-- * most-recent editions of each document of a given content item, which means
-- that different translations of the same content item might have different
-- document_types.
--
-- A typical example is a consultation, which is represented by a different
-- document_type in each part of its lifecycle.
-- 9884ebdc-8135-4d19-909e-94c744dd7798
--
-- 1. coming_soon
-- 2. consultation
-- 3. open_consultation
-- 4. closed_consultation
-- 5. consultation_outcome
--
-- Perhaps it would have made more sense to vary the schema_name, rather than
-- the document_type.  Never mind.

-- Content items that have had more than one document type
with doc_types AS (
select distinct
  content_id,
  locale,
  document_type
from editions inner join documents on documents.id = editions.document_id
)
select content_id, locale, count(*) as n_document_types
from doc_types
group by content_id, locale
having count(*) > 1
order by count(*) desc
limit 10
;

--               content_id              | locale | n_document_types
-- --------------------------------------+--------+------------------
--  0000600f-265d-46b9-9deb-016405b7f369 | en     |                3
--  000061c8-671f-4d51-8e77-16431e827575 | en     |                2
--  0001f1a9-3285-4897-baa9-f6663aeb1e8a | en     |                2
--  00022740-0ba7-4fd0-8ca8-f0c3d6156fec | en     |                2
--  000227a8-f0d2-417d-8ce4-27a18d62d442 | en     |                2
--  00026064-784c-4eca-b24b-0f4b092a329a | en     |                2
--  0002b328-cf71-4271-8360-e0bcc4b6f8fb | en     |                2
--  000308e8-c04c-4416-89ac-f1d2442f77b6 | en     |                2
--  00037b70-5b08-44c2-bf0a-fa8eb636a60b | en     |                2
--  000601a7-19b7-5e92-984a-c2c87ab4d704 | en     |                2

select locale, editions.updated_at, document_type, schema_name
from editions inner join documents on documents.id = editions.document_id
where content_id = '9884ebdc-8135-4d19-909e-94c744dd7798'
order by locale, editions.updated_at
;

-- Current edition of each document, in postgres syntax
CREATE TABLE editions_current AS (
  SELECT DISTINCT ON (content_id, locale)
    documents.content_id,
    documents.locale,
    editions.*
  FROM editions
  INNER JOIN documents ON documents.id = editions.document_id
  WHERE state <> 'draft'
  ORDER BY content_id, locale, updated_at DESC
);

-- Content items that currently have documents whose editions are different
-- document_types.
with doc_types AS (
select distinct
  content_id,
  document_type
from editions_current
)
select content_id, count(*) as n_document_types
from doc_types
group by content_id
having count(*) > 1
order by count(*) desc
limit 10
;

--               content_id              | n_document_types
-- --------------------------------------+------------------
--  004a6456-8fc6-4321-b60b-ca436a8486de |                2
--  5f5c20e9-7631-11e4-a3cb-005056011aef |                2
--  5f56a533-7631-11e4-a3cb-005056011aef |                2
--  5d2b66f9-7631-11e4-a3cb-005056011aef |                2
--  54134a63-e693-4950-9f39-23d03ca6acf6 |                2
--  6055de47-7631-11e4-a3cb-005056011aef |                2
--  87646ce8-ef69-4014-980a-c63b8ccde645 |                2
--  5fa5bc26-7631-11e4-a3cb-005056011aef |                2
--  5f568fb2-7631-11e4-a3cb-005056011aef |                2
--  944c3cde-0915-4dda-bcdb-729eb413d7cd |                2
-- (10 rows)

select locale, document_type, updated_at
from editions_current
where content_id = '004a6456-8fc6-4321-b60b-ca436a8486de'
;

--  locale | document_type |         updated_at
-- --------+---------------+----------------------------
--  cy     | placeholder   | 2017-02-02 14:34:56.063013
--  en     | foi_release   | 2022-05-09 11:03:34.143869
-- (2 rows)

-- Current online editions, in postgres syntax
CREATE TABLE editions_online AS (
  SELECT editions_current.*
  FROM editions_current
  LEFT JOIN unpublishings ON unpublishings.edition_id = editions_current.id
  WHERE
    content_store = 'live'
    AND state <> 'superseded'
    AND coalesce(unpublishings.type <> 'vanish', true)
    AND (
      left(schema_name, 11) <> 'placeholder'
      OR (
        -- schema_name must be checked again because short-circuit evaluation
        -- isn't available in this clause.
        left(schema_name, 11) = 'placeholder'
        AND coalesce(unpublishings.type IN ('gone', 'redirect'), false)
      )
    )
)
;

-- Online content items that currently have documents whose editions are
-- different document_types.
with doc_types AS (
select distinct
  content_id,
  document_type
from editions_online
)
select content_id, count(*) as n_document_types
from doc_types
group by content_id
having count(*) > 1
order by count(*) desc
limit 10
;

--               content_id              | n_document_types
-- --------------------------------------+------------------
--  5e2cef4d-7631-11e4-a3cb-005056011aef |                2
--  5fa5bc26-7631-11e4-a3cb-005056011aef |                2
--  5f568fb2-7631-11e4-a3cb-005056011aef |                2
--  5f56a533-7631-11e4-a3cb-005056011aef |                2
--  54134a63-e693-4950-9f39-23d03ca6acf6 |                2
--  6055de47-7631-11e4-a3cb-005056011aef |                2
--  87646ce8-ef69-4014-980a-c63b8ccde645 |                2
--  6031bb8f-7631-11e4-a3cb-005056011aef |                2
--  8508f8c9-38d3-41d4-a274-8b4cfb7de61c |                2
--  944c3cde-0915-4dda-bcdb-729eb413d7cd |                2

select locale, document_type, updated_at, base_path
from editions_online
where content_id = '944c3cde-0915-4dda-bcdb-729eb413d7cd'
;

--  locale |   document_type    |         updated_at
-- --------+--------------------+----------------------------
--  en     | statutory_guidance | 2023-09-29 10:09:26.803491
--  cy     | policy_paper       | 2021-01-28 09:32:20.036697

-- We tell which editions are new since the last update by inspecting the field
-- `updated_at`, rather than the field `id`, which isn't guaranteed to be
-- sequential, and often isn't.
--
-- Unfortunately, updated_at isn't unique.  See the following query.
--
--   SELECT
--     updated_at,
--     COUNT(*) AS n,
--     ARRAY_AGG(id) AS ids
--   FROM
--     publishing.editions
--   GROUP BY
--     updated_at
--   HAVING
--     n > 1
--   ORDER BY
--     updated_at desc
--
-- It might be possible for multiple rows of the editions table to have the same
-- updated_at time, but not be inserted in the same transaction, which means
-- that they might also not appear in the same nightly backup file.  In case
-- this happens, we always delete the records in the editions_current and
-- editions_online tables that have the most recent updated_at date. Then we can
-- safely treat all records on or after that date as new ones.

-- 1. Filter editions for ones since max(editions_current.updated_at).
-- 2. Query those editions for the current editions of those documents.
-- 3. Delete corresponding editions from editions_current and editions_online.
-- 4. Insert the new current editions into editions_current.
-- 5. Insert the new online editions into editions_online.

-- All documents of schema_name='redirect' define a redirect in the 'redirect'
-- column.  None do that aren't, so schema_name='redirect' is necessary and sufficient to
-- identify redirects.

BEGIN
-- The timestamp of the most recent edition so far
DECLARE max_updated_at TIMESTAMP DEFAULT (
  -- Coalesce for the case when editions_current is empty
  SELECT coalesce(max(updated_at), '0001-01-01 00:00:00+00')
  FROM publishing.editions_current
);
-- In case the same timestamp also exists in a so-far unseen record, delete that
-- record.  Then all records of that timestamp will be treated as though so-far
-- unseen.
DELETE FROM publishing.editions_current WHERE updated_at = max_updated_at;
-- A set of so-far unseen editions.
TRUNCATE TABLE publishing.editions_new;
INSERT INTO publishing.editions_new
  SELECT * FROM publishing.editions WHERE updated_at >= max_updated_at
;
-- Derive from the new editions a table of the latest edition per document, and
-- a flag indicating whether it has a presence online (whether a redirect,
  -- or embedded in other pages, or a page in its own right).
TRUNCATE TABLE publishing.editions_new_current;
INSERT INTO publishing.editions_new_current
  SELECT
    documents.content_id,
    documents.locale,
    editions_new.*,
    -- TODO: derive other values here
    (
      coalesce(content_store = 'live', false) -- Includes items that are only embedded in others.
      AND state <> 'superseded' -- Exclude this rare and illogical case
      AND coalesce(unpublishings.type <> 'vanish', true)
      AND (
        coalesce(left(schema_name, 11) <> 'placeholder', true)
        OR (
          -- schema_name must be checked again because short-circuit evaluation
          -- isn't available in this clause.
          coalesce(left(schema_name, 11) = 'placeholder', false)
          AND coalesce(unpublishings.type IN ('gone', 'redirect'), false)
        )
      )
    ) AS is_online
  FROM publishing.editions_new
  INNER JOIN publishing.documents ON documents.id = editions_new.document_id
  LEFT JOIN publishing.unpublishings ON unpublishings.edition_id = editions_new.id
  WHERE state <> 'draft'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY content_id, locale ORDER BY updated_at DESC) = 1
;
-- Delete rows from the editions_current table where a newer edition of the same
-- document is now available.
MERGE INTO
publishing.editions_current AS target
USING publishing.editions_new_current AS source
ON source.content_id = target.content_id AND source.locale = target.locale
WHEN matched THEN DELETE
;
-- Insert the new editions into the editions_current table
INSERT INTO publishing.editions_current
SELECT * FROM publishing.editions_new_current
;
END
