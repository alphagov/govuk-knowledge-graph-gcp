// HTML content of document types that have it in the "body.content" field.
db.content_items.aggregate([
  { $match: { "schema_name": { $in: [
    "answer",
    "help_page",
    "manual",
    "manual_section",
    "person",
    "role",
    "simple_smart_answer",
    "specialist_document"
  ] } } },
  { $project: { "url": true, "details.body": true } },
  // Omit govspeak content
  { $redact: {
    $cond: {
      if: { $or: [
        { $eq:  [ { $type : "$content_type"}, 'missing'] },
        { $eq: [ "$content_type", "text/html" ] },
      ] },
      then: "$$DESCEND",
      else: "$$PRUNE"
    },
  } },
  { $project: { "url": true, "details.body.content": true } },
  { $unwind: "$details.body" },
  { $project: { url: true, html: "$details.body.content" } },
  { $match: { "html": { "$exists": true, $ne: null } } },
  { $out: "body_content"}
])
