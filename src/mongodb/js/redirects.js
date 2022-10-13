// Redirects
db.content_items.aggregate([
  { $match: {
    "redirects": { $exists: true, $type: 'object', $ne: { } }
  } },
  { $project: {
    _id: false,
    url: true,
    redirects: true,
  } },
  { $unwind: "$redirects" },
  { $project: {
    "redirects.path": true,
    "redirects.destination": true,
  } },
  { $group: {
    _id: null,
    redirects: { $addToSet: "$redirects" },
    } },
  { $unwind: "$redirects" },
  { $project: {
    _id: false,
    from: "$redirects.path",
    to: "$redirects.destination",
  } },
  { $project: {
    from: { "$concat": [ "https://www.gov.uk", "$from" ] },
    to: { $cond: {
      if: { "$regexMatch": { input: "$to", regex: /^\// } },
      then: { "$concat": [ "https://www.gov.uk", "$to" ] },
      else: "$to"
    } },
  } },
  { $out: "redirects" }
])
