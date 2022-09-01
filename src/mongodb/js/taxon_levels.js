// Taxon levels from the root, which is the homepage
db.content_items.aggregate([
  { $match: { document_type: "taxon" } },
  { $project: {
    "children": "$expanded_links.child_taxons.base_path",
  } },
  { $out: "taxons" }
])
db.content_items.aggregate([
  { $match: { "_id": "/" } },
  { $project: { "children": "$expanded_links.level_one_taxons.base_path" } },
  { $graphLookup: {
        from: "taxons",
        startWith: "$children",
        connectFromField: "children",
        connectToField: "_id",
        as: "descendants",
        depthField: "level",
     } },
  { $project: { "descendants._id": true, "descendants.level": true } },
  { $unwind: "$descendants" },
  { $set: {
    "url": { "$concat": [ "https://www.gov.uk", "$descendants._id" ] },
    "level": { $add: [ "$descendants.level", 1 ] }
  } },
  { $project: {
    _id: false,
    "url": true,
    "level": true,
  } },
  { $out: "taxon_levels" }
])
