// The steps that each new edition has gone through up to publication.
// Can by joined to the editions table by the url and version_number.

db.editions.aggregate([
  // 'archived' editions were once 'published', and have since been superseded by
  // a later edition.
  { $match: { "state": { $in: [ "published", "archived" ] } } },
  { $match: { "slug": { $ne: null } } },
  { $unwind: "$actions" },
  { $addFields: {
    "action_created_at": "$actions.created_at",
    "action_request_type": "$actions.request_type"
  } },
  { $unset: "actions" },
  { $project: {
    _id: false,
    "url": { "$concat": [ "https://www.gov.uk/", "$slug" ] },
    version_number: true, // sequence, sometimes in a different order from updated_at e.g. /1619-bursary-fund
    action_created_at: true,
    action_request_type: true,
  } },
  { $out: "actions_output"},
])
