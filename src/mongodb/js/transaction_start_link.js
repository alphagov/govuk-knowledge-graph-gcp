// Get transaction start links, resolve to https://www.gov.uk when necessary,
// and strip parameters and fragments
db.content_items.aggregate([
  { $match: { "document_type": "transaction" } },
  { $match: {
    "details.transaction_start_link": { $exists: true, $ne:null, $ne: "" }
  } },
  { $project: {
    url: 1,
    link_url: "$details.transaction_start_link",
  } },
  { $project: {
    url: 1,
    link_url: { $switch: {
       branches: [
          {
            case: { "$regexMatch": { input: "$link_url", regex: /^\// } },
            then: { "$concat": [ "https://www.gov.uk", "$link_url" ] }
          },
          {
            case: { "$regexMatch": { input: "$link_url", regex: /^#/ } },
            then: { "$concat": [ "$url", "$link_url" ] }
          },
       ],
       default: "$link_url"
    } },
  } },
  { $project: {
    url: true,
    link_url: true,
    anchors_removed: { "$first": { "$split": [ "$link_url", "?" ] } },
  } },
  { $project: {
    url: true,
    link_url: true,
    parameters_removed: { "$first": { "$split": [ "$anchors_removed", "#" ] } },
  } },
  { $project: {
    url: true,
    link_url: true,
    link_url_bare: "$parameters_removed",
  } },
  { $out: "transaction_start_link" }
])
