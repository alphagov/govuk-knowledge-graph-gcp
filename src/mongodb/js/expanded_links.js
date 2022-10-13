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
  { $match: { "links.base_paths": { $exists: true, $ne: null } } },
  { $project: {
    "_id": false,
    "link_type": "$links.link_type",
    "from_url": "$url",
    "to_url": { "$concat": [ "https://www.gov.uk", "$links.base_paths" ] },
  } },
  { $out: "expanded_links" }
])
