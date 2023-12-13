// Phone numbers from 'contact' documents embedded in other pages. Each contact
// can appear in many pages.
//
// Only the 'title' and 'number' fields are ever used, because the Whitehall app
// doesn't support the other fields.  They are included here in case that changes.
db.content_items.aggregate([
  // { $match: {
  //   "_id": "/world/organisations/british-embassy-reykjavik/office/british-embassy"
  // } },
  { $match: {
    "expanded_links": { $exists: true, $type: 'object', $ne: { } }
  } },
  // Form the contacts into an array of k:v pairs per document, where the k is
  // the kind of link.
  { $project: { "url": true, "links": { $objectToArray: "$expanded_links" } } },
  // Filter links for ones that are contacts
  { $project: {
      "url": true,
      contacts: {$filter: {
          input: '$links',
          as: 'link',
          cond: {$eq: ['$$link.k', 'contact']}
      }}
  }},
  // Create one MongoDB document per phone number, per contact
  { $unwind: "$contacts" },
  { $unwind: "$contacts.v" },
  { $unwind: "$contacts.v.details.phone_numbers" },
  // Prepare for CSV export
  { $project: { "url": true, "phone_numbers": "$contacts.v.details.phone_numbers" } },
  { $project: {
    "_id": false,
    "url": true,
    "title": "$phone_numbers.title",
    "number": "$phone_numbers.number",
    "textphone": "$phone_numbers.textphone",
    "international_phone": "$phone_numbers.international_phone",
    "fax": "$phone_numbers.fax",
    "description": "$phone_numbers.description",
    "open_hours": "$phone_numbers.open_hours",
    "best_time_to_call": "$phone_numbers.best_time_to_call",
  } },
  { $out: "phone_number" }
])
