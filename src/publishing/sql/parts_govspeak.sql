-- Govspeak content of parts of 'guide' and 'travel_advice' documents, which map
-- several URLs to a single document in the content store.
drop table if exists parts;
create table parts as
select
  id,
  content_id,
  base_path,
  part.index as index,
  part.object->>'slug' as slug,
  part.object->>'title' as title,
  jsonb_path_query_array(
    part.object,
    '$.body[*]?(@.content_type == "text/govspeak").content'
  ) as govspeak
from
  editions_online,
  lateral jsonb_array_elements(details->'parts') with ordinality as part(object, index)
where schema_name in ('guide', 'travel_advice')
;
select * from parts;
