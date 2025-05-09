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
  // There is one special-case document that has no slug, which is "popular
  // links". That document is rendered as part of the homepage. When it is
  // published to the Publishing API, its Content ID is hardcoded to
  // ad7968d0-0339-40b2-80bc-3ea1db8ef1b7, and its base_path is null. The
  // results of this query are joined to the Publishing API editions by
  // base_path (or url, whatever), and null can't be joined to null. So, even if
  // we were to allow nulls in the url/base_path column in BigQuery, we'd have
  // to hardcode a special case to make the join work for the "popular links"
  // document. It isn't worthwhile, so the document is omitted here.
  // https://github.com/alphagov/publisher/blob/a01d44291a85e7809cc0f85273c26fea5a7aed3a/app/models/popular_links_edition.rb#L49
  { $match: { "slug": { $ne: null } } },
  { $project: {
    _id: false,
    "url": { "$concat": [ "https://www.gov.uk/", "$slug" ] },
    // created_at: true, // when the edition was first drafted
    updated_at: true, // almost but not quite the same time as the updated_at of the corresponding edition in the Publishing API.
    version_number: true, // sequence, sometimes in a different order from updated_at e.g. /1619-bursary-fund
    state: true, // 'published', or 'archived' if superseded
    major_change: true, // not often true
    type: "$_type", // 'GuideEdition', 'SmartAnswerEdition', etc.
  } },
  { $out: "editions_output"},
])
