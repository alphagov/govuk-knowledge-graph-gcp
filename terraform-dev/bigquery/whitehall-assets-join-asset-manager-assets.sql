--- JOIN the Whitehall assets table to the Asset Manager assets table via the asset manager ID
--- Only include data for assets associated with editions
--- Only include data for attachments (images are excluded)
select wh_att_data.id as ad_id,
       wh_assets.filename,
       wh_assets.asset_manager_id,
       wh_attachments.id as attachment_id,
       wh_attachments.title as attachment_title,
       wh_attachments.deleted as attachment_deleted,
       wh_editions.state as attachable_state,
       wh_editions.id as attachable_id,
       wh_editions.updated_at as attachable_updated_at,
       am_assets.deleted_at,
       am_assets.draft,
       am_assets.replacement_id,
       am_assets.redirect_url
from whitehall.attachment_data as wh_att_data
join whitehall.attachments as wh_attachments on wh_attachments.attachment_data_id = wh_att_data.id
join whitehall.assets as wh_assets on wh_assets.assetable_id = wh_att_data.id and wh_assets.assetable_type = 'AttachmentData'
join whitehall.editions as wh_editions on wh_editions.id = wh_attachments.attachable_id and wh_attachments.attachable_type = 'Edition'
join asset_manager.assets as am_assets on am_assets._id = wh_assets.asset_manager_id