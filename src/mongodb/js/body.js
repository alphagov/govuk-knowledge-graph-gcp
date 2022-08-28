// HTML content of document types that have it in the "body" field.
db.content_items.aggregate([
  { $match: { "document_type": { $in: [
    "service_manual_service_standard",
    "calendar",
    "petitions_and_campaigns",
    "world_location_news_article",
    "history",
    "standard",
    "detailed_guidance",
    "take_part",
    "staff_update",
    "access_and_opening",
    "modern_slavery_statement",
    "our_energy_use",
    "terms_of_reference",
    "about_our_services",
    "statistics",
    "membership",
    "welsh_language_scheme",
    "topical_event_about_page",
    "social_media_use",
    "equality_and_diversity",
    "media_enquiries",
    "open_consultation",
    "procurement",
    "publication_scheme",
    "accessible_documents_policy",
    "recruitment",
    "personal_information_charter",
    "our_governance",
    "complaints_procedure",
    "service_manual_guide",
    "map",
    "fatality_notice",
    "authored_article",
    "government_response",
    "working_group",
    "oral_statement",
    "regulation",
    "statistical_data_set",
    "closed_consultation",
    "about",
    "organisation",
    "international_treaty",
    "promotional",
    "statutory_guidance",
    "impact_assessment",
    "written_statement",
    "case_study",
    "independent_report",
    "consultation_outcome",
    "document_collection",
    "form",
    "correspondence",
    "decision",
    "detailed_guide",
    "speech",
    "foi_release",
    "policy_paper",
    "national_statistics",
    "corporate_report",
    "research",
    "transparency",
    "official_statistics",
    "notice",
    "world_news_story",
    "guidance",
    "press_release",
    "news_story",
    "html_publication",
    "hmrc_manual_section"
  ] } } },
  { $project: { url: true, html: "$details.body" } },
  { $out: "body"}
])
