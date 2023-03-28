db.content_items.aggregate([
  { $match: { $and: [
    { "details.organisation_govuk_status": { $exists: true } },
    { "details.organisation_govuk_status.status": { $ne: "live" } },
  ] } },
  { $project: {
    url: true,
    status: "$details.organisation_govuk_status.status",
    updated_at: "$details.organisation_govuk_status.updated_at",
    organisation_url: "$details.organisation_govuk_status.url",
  } },
  { $out: "organisation_govuk_status" }
])
