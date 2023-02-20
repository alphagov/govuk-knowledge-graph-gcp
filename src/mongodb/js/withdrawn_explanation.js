// The explanation is HTML, unless the document type is 'need', when it is
// plain text.  We extract it all into a column called "HTML", and then extract
// plain text from it.  That works whether it is HTML or not.
//
// The plain text can include a kind of embedded link, for example:
// "This need is a duplicate of: [embed:link:1dd60ca1-482b-4e90-9b13-b38bc54f1e51]"
// We don't extract those links.
db.content_items.aggregate([
  { $match: { "withdrawn_notice.explanation": { $exists: true } } },
  { $project: { url: true, html: "$withdrawn_notice.explanation" } },
  { $out: "withdrawn_explanation" }
])
