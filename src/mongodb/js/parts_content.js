// html content of parts of "guide" and "travel_advice"
db.content_items.aggregate([
  { $match: { "details.parts": { $exists: true } } },
  { $project: {
    "_id": false,
    "base_path": "$url",
    // Reshape the summary object, whether or not it exists.
    "summary": { $cond: {
      // If $details.summary exists
      // https://stackoverflow.com/a/25515046/937932
      if: { $gt: [ "$details.summary", null ] },
      // Then reshape it to be like the other parts. Creating the slug as null
      // makes it possible to avoid ending the URL with a trailing slash.
      then: [ { body: "$details.summary", slug: null, title: "Summary" } ],
      // otherwise return an empty array (null causes concatenation to also be
      // null too)
      else: []
    } },
    "details.parts": true
  } },
  { $project: {
    "_id": false,
    "base_path": true,
    // Concatenate the (possibly empty) summary with the other parts
    "all_parts": { $concatArrays: [
        "$summary" ,
       "$details.parts",
    ] }
  } },
  { $unwind: { path: "$all_parts", includeArrayIndex: "part_index" } },
  { $project: {
    "base_path": true,
    "part_index": true,
    "slug": "$all_parts.slug",
    "part_title": "$all_parts.title",
    "body": { $filter: {
      input: "$all_parts.body",
      as: "item",
      cond: { $eq: [ "$$item.content_type", "text/html" ] }
    } },
  } },
  { $unwind: { path: "$body" } },
  { $project: {
    // Append a slash and the slug to the the URL, if the slug exists.
    "url": { $ifNull: [
        { $concat: [ "$base_path", "/", "$slug"] },
        "$base_path"
      ] },
    "base_path": true,
    "slug": true,
    "part_index": true,
    "part_title": true,
    "html": "$body.content",
  } },
  { $match: { "html": { "$exists": true, $ne: null } } },
  {$out: "parts_content"}
])
