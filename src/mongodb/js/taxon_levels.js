// Taxon levels from the roots, which are currently the homepage, a hierarchy of
// world taxons, and some odd others.
db.content_items.aggregate([
  { $match: { "document_type": { "$in": ["homepage", "taxon"] } } },
  { $project: {
    "homepage_url": { "$concat": [ "https://www.gov.uk", "$_id" ] },
    "_id": "$content_id",
    "children": { "$concatArrays": [
      { "$ifNull": [ "$expanded_links.level_one_taxons.content_id", [] ] },
      { "$ifNull": [ "$expanded_links.child_taxons.content_id", [] ] },
    ] },
  } },
  { $out: "taxons" }
])

// root_taxons:
db.content_items.aggregate([
  { $match: { "document_type": { "$in": ["homepage", "taxon"] } } },
  { $match: { "expanded_links.parent_taxons": { "$exists": false } } },
  { $match: { "expanded_links.root_taxon": { "$exists": false } } },
  { $project: {
    _id: false,
    "homepage_url": { "$concat": [ "https://www.gov.uk", "$_id" ] },
    "_id": false,
    "children": { "$concatArrays": [
      [ "$content_id" ] ,
    ] },
  } },
  { $graphLookup: {
        from: "taxons",
        startWith: "$children",
        connectFromField: "children",
        connectToField: "_id",
        // connectToField: "content_id",
        as: "descendants",
        depthField: "level",
     } },
  { $project: {
    "descendants._id": true,
    "descendants.homepage_url": true,
    "descendants.level": true
  } },
  { $unwind: "$descendants" },
  { $set: {
    "url": { "$concat": [ "https://www.gov.uk/", "$descendants._id" ] },
    "homepage_url": "$descendants.homepage_url",
    "level": { $add: [ "$descendants.level", 0 ] }
  } },
  { $project: {
    _id: false,
    "url": true,
    "homepage_url": true,
    "level": true,
  } },
  { $out: "taxon_levels" }
])
