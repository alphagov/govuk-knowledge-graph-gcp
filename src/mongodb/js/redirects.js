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
    from_url: { "$concat": [ "https://www.gov.uk", "$from" ] },
    to_url: { $cond: {
      if: { "$regexMatch": { input: "$to", regex: /^\// } },
      then: { "$concat": [ "https://www.gov.uk", "$to" ] },
      else: "$to"
    } },
  } },
  { $project: {
    from_url: true,
    to_url: true,
    anchors_removed: { "$first": { "$split": [ "$to_url", "?" ] } },
  } },
  { $project: {
    from_url: true,
    to_url: true,
    parameters_removed: { "$first": { "$split": [ "$anchors_removed", "#" ] } },
  } },
  { $project: {
    from_url: true,
    to_url: true,
    to_url_bare: "$parameters_removed",
  } },
  { $out: "redirects" }
])
