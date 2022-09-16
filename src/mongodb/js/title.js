// Get the title from documents and strip leading and trailing whitespace
db.content_items.aggregate([
  { $match: { $and: [
    { "title": { $exists: true } },
    { "title": { $ne: null } },
    { "title": { $ne: "" } },
  ] } },
  { $project: { url: 1, title: { "$trim": { input: "$title" } } } },
  { $out: "title" }
])
