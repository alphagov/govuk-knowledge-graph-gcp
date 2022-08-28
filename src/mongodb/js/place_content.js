// HTML content of "place", following the schema:
// https://github.com/alphagov/govuk-content-schemas/blob/main/dist/formats/place/frontend/schema.json
db.content_items.aggregate([
  { $match: { "document_type": "place" } },
  { $project: {
    "url": true,
    "details.introduction": true,
    "details.information": true,
    "details.need_to_know": true,
  } },
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
  { $project: {
    "url": true,
    introduction: { $map: {
      input: "$details.introduction",
      as: "item",
      in: "$$item.content"
    } },
    more_information: { $map: {
      input: "$details.more_information",
      as: "item",
      in: "$$item.content"
    } },
    need_to_know: { $map: {
      input: "$details.need_to_know",
      as: "item",
      in: "$$item.content"
    } },
  } },
  { $project: {
    "url": true,
    content: { $concatArrays: [
      { $ifNull: [ "$introduction", [] ] },
      { $ifNull: [ "$more_information", [] ] },
      { $ifNull: [ "$need_to_know", [] ] },
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
  { $out: "place_content" }
])
