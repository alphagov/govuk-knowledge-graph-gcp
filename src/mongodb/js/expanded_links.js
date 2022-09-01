// All types of expanded links
db.content_items.aggregate([
  { $match: {
    "expanded_links": { $exists: true, $type: 'object', $ne: { } }
  } },
  { $project: { "url": true, "links": { $objectToArray: "$expanded_links" } } },
  { $project: {
    "url": true,
    "links": { $map: {
      input: "$links",
      as: "link",
      in: {
        link_type: "$$link.k",
        base_paths: { $reduce: {
          input: "$$link.v",
          initialValue: [ ],
          in: { $concatArrays : ["$$value", [ "$$this.base_path" ] ] }
        } }
      }
    } }
  } },
  { $unwind: "$links" },
  { $unwind: "$links.base_paths" },
  { $project: {
    "_id": false,
    "link_type": "$links.link_type",
    "from_url": "$url",
    "to_url": { "$concat": [ "https://www.gov.uk", "$links.base_paths" ] },
  } },
  { $out: "expanded_links" }
])

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
  { $out: "expanded_links_content_ids" }
])
