// HTML content of "transaction", following the schema:
// https://github.com/alphagov/govuk-content-schemas/blob/main/dist/formats/transaction/frontend/schema.json
db.content_items.aggregate([
  { $match: { "schema_name": { $in: [
    "licence",
    "local_transaction",
    "transaction"
  ] } } },
  { $project: {
    "url": true,
    "details.introductory_paragraph": true, // transaction
    "details.introduction": true, // local_transaction
    "details.licence_overview": true, // licence
    "details.start_button_text": true, // transaction
    "details.will_continue_on": true, // transaction
    "details.more_information": true, // transaction, local_transaction
    "details.what_you_need_to_know": true, // transaction
    "details.need_to_know": true, // local_transaction
    "details.other_ways_to_apply": true, // transaction
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
      { $ifNull: [ "$details.introductory_paragraph.content", [] ] }, // transaction
      { $ifNull: [ "$details.introduction.content", [] ] }, // local_transaction
      { $ifNull: [ "$details.licence_overview.content", [] ] }, // licence
      [ { $ifNull: [ "$details.start_button_text", "" ] } ], // transaction
      { $ifNull: [ "$details.will_continue_on.content", [] ] }, // transaction
      { $ifNull: [ "$details.more_information.content", [] ] }, // transaction, local_transaction
      { $ifNull: [ "$details.what_you_need_to_know.content", [] ] }, // transaction
      { $ifNull: [ "$details.need_to_know.content", [] ] }, // local_transaction
      { $ifNull: [ "$details.other_ways_to_apply.content", [] ] }, // transaction
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
