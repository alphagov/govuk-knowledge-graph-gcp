db.content_items.updateMany(
  {}, // everything
  [
    { $set: { "url": { "$concat": [ "https://www.gov.uk", "$_id" ] } } },
  ]
)
