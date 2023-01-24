// All types of expanded links, by content_id
db.content_items.aggregate([
  { $match: {
    "expanded_links": { $exists: true, $type: 'object', $ne: { } }
  } },
  { $project: { "content_id": true, "links": { $objectToArray: "$expanded_links" } } },
  { $project: {
    "content_id": true,
    "links": { $map: {
      input: "$links",
      as: "link",
      in: {
        link_type: "$$link.k",
        content_ids: { $reduce: {
          input: "$$link.v",
          initialValue: [ ],
          in: { $concatArrays : ["$$value", [ "$$this.content_id" ] ] }
        } }
      }
    } }
  } },
  { $unwind: "$links" },
  { $unwind: "$links.content_ids" },
  { $project: {
    "_id": false,
    "link_type": "$links.link_type",
    "from_content_id": "$content_id",
    "to_content_id": "$links.content_ids",
  } },
  { $match: {
    "to_content_id": { $ne: null }
  } },
  // De-duplicate, which happens when a content item has multiple translations,
  // because each translation has its own document in this database, so the
  // links between content items are represented in each document.
  { $group: {
    "_id": {
      "link_type": "$link_type",
      "from_content_id": "$from_content_id",
      "to_content_id": "$to_content_id",
    },
  } },
  { $project: {
    "_id": false,
    "link_type": "$_id.link_type",
    "from_content_id": "$_id.from_content_id",
    "to_content_id": "$_id.to_content_id",
  } },
  { $out: "expanded_links_content_ids" },
  // allowDiskUse is needed for $group when the dataset is this big, and isn't set
  // by default in all versions of MongDB
], { allowDiskUse: true })
