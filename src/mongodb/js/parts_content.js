// html content of parts of "guide" and "travel_advice"
db.content_items.aggregate([
  { $match: { "details.parts": { $exists: true } } },
  { $project: {
    "_id": false,
    "base_path": "$url",
    "details.parts": true,
  } },
  { $unwind: { path: "$details.parts", includeArrayIndex: "part_index" } },
  { $project: {
    base_path: true,
    part_index: true,
    slug: "$details.parts.slug",
    part_title: "$details.parts.title",
    body: { $filter: {
      input: "$details.parts.body",
      as: "item",
      cond: { $eq: [ "$$item.content_type", "text/html" ] }
    } },
  } },
  { $unwind: { path: "$body" } },
  { $project: {
    "url": { $concat: ["$base_path", "/", "$slug"] },
    "base_path": true,
    "slug": true,
    "part_index": true,
    "title": true,
    "html": "$body.content",
  } },
  { $match: { "html": { "$exists": true, $ne: null } } },
  {$out: "parts_content"}
])
