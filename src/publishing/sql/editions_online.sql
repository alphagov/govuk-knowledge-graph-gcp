-- Editions that are being used by the website, either in the content store as
-- documents in their own right, or as expanded links, or as search results.
DROP TABLE IF EXISTS editions_online;
CREATE TABLE editions_online AS
select editions_current.*
from editions_current
left join unpublishings on unpublishings.edition_id = editions_current.id
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
;
