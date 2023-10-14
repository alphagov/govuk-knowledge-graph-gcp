-- Note:
-- > In cases when there are edition links and link set links which have the
-- > same link_type, the edition links will take precedence during link
-- > expansion.
-- https://docs.publishing.service.gov.uk/repos/publishing-api/link-expansion.html

drop table if exists links_online;
create table links_online as
with edition_links as (
  select
    origin.content_id as origin_content_id,
    origin.locale as origin_locale,
    origin.id as origin_edition_id,
    links.link_type,
    'edition' as origin_type,
    target.content_id as target_content_id,
    target.locale as target_locale,
    target.id as target_edition_id
  from links
  inner join editions_online as origin on origin.id = links.edition_id
  inner join editions_online as target on target.content_id = links.target_content_id
),
link_set_links as (
  select
    origin.content_id as origin_content_id,
    origin.locale as origin_locale,
    origin.id as origin_edition_id,
    links.link_type,
    'link set' as origin_type,
    target.content_id as target_content_id,
    target.locale as target_locale,
    target.id as target_edition_id
  from links
  inner join link_sets on link_sets.id = links.link_set_id
  inner join editions_online as origin on origin.content_id = link_sets.content_id
  inner join editions_online as target on target.content_id = links.target_content_id
  -- Omit ones that already exist in edition_links for the same origin edition and
  -- link_type.
  -- > In cases when there are edition links and link set links which have the
  -- > same link_type, the edition links will take precedence during link
  -- > expansion.
  -- https://docs.publishing.service.gov.uk/repos/publishing-api/link-expansion.html
  left join edition_links on
    edition_links.origin_edition_id = origin.id
    and edition_links.link_type = links.link_type
  where edition_links.origin_edition_id is null
)
select * from edition_links
union all
select * from link_set_links
;

-- Check that there are no editions that have links by both edition_id and
-- content_id for the same link_type.  Expect zero rows.
-- > In cases when there are edition links and link set links which have the
-- > same link_type, the edition links will take precedence during link
-- > expansion.
-- https://docs.publishing.service.gov.uk/repos/publishing-api/link-expansion.html
--
-- with distinct_origin_types as (
--   select distinct origin_edition_id, link_type, origin_type from links_online
-- )
-- select origin_edition_id, link_type, count(*) as n_origin_types
-- from distinct_origin_types
-- group by origin_edition_id, link_type
-- having count(*) > 1
-- limit 1
-- ;

select * from links_online;
