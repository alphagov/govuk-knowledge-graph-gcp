// All step-by-step content as a string, following the schema:
// https://github.com/alphagov/govuk-content-schemas/blob/main/dist/formats/step_by_step_nav/frontend/schema.json
db.content_items.aggregate([
  { $match: { "schema_name": { $in: [
    "step_by_step_nav"
  ] } } },
  { $project: {
    url: true,
    introduction: { $filter: { // only the govspeak version
      input: "$details.step_by_step_nav.introduction",
      as: "item",
      cond: { $eq: [ "$$item.content_type", "text/html" ] }
    } },
    steps: "$details.step_by_step_nav.steps"
  } },
  { $project: {
    url: true,
    introduction: "$introduction.content", // returns an array element
    content: { $map: {
      input: "$steps",
      as: "step",
      in: [ "$$step.title",
        { $map: {
          input: "$$step.contents",
          as: "task",
          in: { $switch: { branches: [
            {
              case: { $eq: [ "$$task.type", "paragraph" ] },
              then: "$$task.text"
            },
            {
              case: { $eq: [ "$$task.type", "list" ] },
              then: { $map: {
                input: "$$task.contents",
                as: "entry",
                in: "$$entry.text"
              } },
            }
          ] } }
        } }
      ]
    } }
  } },
  // Flatten the nested array (might be slow)
  // Requires MongoDB version >= 4.4
  // https://www.mongodb.com/docs/manual/reference/operator/aggregation/function/
  // https://stackoverflow.com/a/67288708
  { $project: {
    url: true,
    introduction: true, // still an array element
    content: {
      $function: {
        body: function(data) {
          const flatten = arr => arr.reduce((a, b) => a.concat(Array.isArray(b) ? flatten(b) : b), []);
          return flatten(data);
        },
        args: ["$content"],
        lang: "js"
      }
    }
  } },
  // Concatenate all the strings, separated by newlines
  { $project: {
    url: true,
    content: { $concatArrays: [ "$introduction", "$content" ] },
  } },
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
  { $out: "step_by_step_content" }
])
