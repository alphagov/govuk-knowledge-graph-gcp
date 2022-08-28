// Get the description from documents, discarding nulls and empty strings, and
// stripping leading and trailing whitespace. Newlines aren't removed from the
// middle of the string because there is only one known page that has newlines
// in its description:
// https://www.gov.uk/aaib-reports/aaib-investigation-to-druine-d-dot-31-turbulent-g-arnz
db.content_items.aggregate([
  { $match: { $and: [
    { "description.value": { $exists: true } },
    // A handful of documents have description.value.value, which is null.
    // These seme to be glitches, because it isn't part of their official schema
    // in https://github.com/alphagov/govuk-content-schemas/.
    // Example: https://www.gov.uk/change-your-charity-structure.cy
    { "description.value.value": { $exists: false } },
    { "description.value": { $ne: null } },
    { "description.value": { $ne: "" } },
  ] } },
  { $project: { url: 1, description: { "$trim": { input: "$description.value" } } } },
  { $out: "description" }
])
