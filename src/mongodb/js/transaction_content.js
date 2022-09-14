// HTML content of "transaction", following the schema:
// https://github.com/alphagov/govuk-content-schemas/blob/main/dist/formats/transaction/frontend/schema.json
db.content_items.aggregate([
  { $match: { "document_type": "transaction" } },
  { $project: {
    "url": true,
    "details.introductory_paragraph": true,
    "details.start_button_text": true,
    "details.will_continue_on": true,
    "details.more_information": true,
    "details.what_you_need_to_know": true,
    "details.other_ways_to_apply": true,
  } },
  // Omit govspeak content
  { $redact: {
    $cond: {
      if: { $or: [
        { $eq: [ { $type : "$content_type"}, 'missing'] },
        { $eq: [ "$content_type", "text/html" ] },
      ] },
      then: "$$DESCEND",
      else: "$$PRUNE"
    },
  } },
  { $project: {
    url: true,
    content: { $concatArrays: [
      { $ifNull: [ "$details.introductory_paragraph.content", [] ] },
      [ { $ifNull: [ "$details.start_button_text", "" ] } ],
      { $ifNull: [ "$details.will_continue_on.content", [] ] },
      { $ifNull: [ "$details.more_information.content", [] ] },
      { $ifNull: [ "$details.what_you_need_to_know.content", [] ] },
      { $ifNull: [ "$details.other_ways_to_apply.content", [] ] },
    ] }
  } },
  // Concatenate all the strings, separated by newlines
  { $project: {
    url: true,
    html: {
      $reduce: {
        input: "$content",
        initialValue: "",
        in: { $concat: ["$$value", "\n", "$$this"] }
      }
    }
  } },
  { $match: { "html": { "$exists": true, $ne: null } } },
  { $out: "transaction_content" }
])
