// The timestamp of every edition of every document in the Publisher app, with
// some other metadata.  This date is more meaningful than the updated_at field
// of the Publishing API, which includes many 'editions' that only exist for techy
// reasons rather than editing reasons.
//
// db = govuk_content_production
db.editions.aggregate([
  // 'archived' editions were once 'published', and have since been superseded by
  // a later edition.
  { $match: { "state": { $in: [ "published", "archived" ] } } },
  { $project: {
    _id: false,
    "url": { "$concat": [ "https://www.gov.uk/", "$slug" ] },
    // created_at: true, // when the edition was first drafted
    updated_at: true, // almost but not quite the same time as the updated_at of the corresponding edition in the Publishing API.
    version_number: true, // sequence, sometimes in a different order from updated_at e.g. /1619-bursary-fund
    state: true, // 'published', or 'archived' if superseded
    major_change: true, // not often true
  } },
  { $out: "output"},
])
