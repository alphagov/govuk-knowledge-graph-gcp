// Taxon levels from the root, which is the homepage
db.content_items.aggregate([
  { $match: { document_type: "taxon" } },
  { $project: {
    "homepage_url": { "$concat": [ "https://www.gov.uk", "$_id" ] },
    "_id": "$content_id",
    "children": "$expanded_links.child_taxons.content_id",
  } },
  { $out: "taxons" }
])
db.content_items.aggregate([
  { $match: { "_id": "/" } },
  { $project: {
    _id: false,
    homepage_url: true,
    "children": "$expanded_links.level_one_taxons.content_id",
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
    "level": { $add: [ "$descendants.level", 1 ] }
  } },
  { $project: {
    _id: false,
    "url": true,
    "homepage_url": true,
    "level": true,
  } },
  { $out: "taxon_levels" }
])
