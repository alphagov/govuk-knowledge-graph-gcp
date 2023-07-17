// HTML content of document types that have it in the "body" field.
db.content_items.aggregate([
  { $match: { "schema_name": { $in: [
    "calendar",
    "case_study",
    "consultation",
    "corporate_information_page",
    "detailed_guide",
    "document_collection",
    "fatality_notice",
    "historic_appointment",
    "history",
    "hmrc_manual_section",
    "html_publication",
    "news_article",
    "organisation",
    "publication",
    "service_manual_guide",
    "service_manual_service_standard",
    "speech",
    "statistical_data_set",
    "take_part",
    "topical_event",
    "topical_event_about_page",
    "working_group",
    "worldwide_corporate_information_page",
    "worldwide_office",
    "worldwide_organisation",
  ] } } },
  { $project: {
    url: true,
    html: { $concat: [
      { $ifNull: ["$details.body", "\n" ] },
      { $ifNull: ["$details.access_and_opening_times", "\n" ] }, // worldwide_office
      { $ifNull: ["$details.born", "\n" ] }, // historic_appointment
      { $ifNull: ["$details.died", "\n" ] }, // historic_appointment
      { $ifNull: ["$details.major_acts", "\n" ] }, // historic_appointment
      { $ifNull: ["$details.mission_statement", "\n" ] }, // world_location_news
    ] }
  } },
  { $match: { "html": { "$exists": true, $ne: null } } },
  { $out: "body"}
])
