// Taxon url override (like a redirect)
db.content_items.aggregate([
  { $match: {
    "redirects": { $exists: true, $ne:null, $ne: "" }
  } },
  { $project: {
    url: true,
    "url_override": { $switch: {
       branches: [
          {
            case: { "$regexMatch": { input: "$details.url_override", regex: /^\\/ } },
            then: { "$concat": [ "https://www.gov.uk", "$link_url" ] }
          },
          {
            case: { "$regexMatch": { input: "$details.url_override", regex: /^#/ } },
            then: { "$concat": [ "$url", "$link_url" ] }
          },
       ],
       default: "$details.url_override"
    } },
  } },
  { $out: "url_override" }
])
