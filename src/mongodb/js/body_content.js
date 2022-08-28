// HTML content of document types that have it in the "body.content" field.
db.content_items.aggregate([
  { $match: { "document_type": { $in: [
    "aaib_report",
    "answer",
    "asylum_support_decision",
    "business_finance_support_scheme",
    "cma_case",
    "countryside_stewardship_grant",
    "dfid_research_output",
    "drcf_digital_markets_research",
    "drug_safety_update",
    "employment_appeal_tribunal_decision",
    "employment_tribunal_decision",
    "esi_fund",
    "export_health_certificate",
    "flood_and_coastal_erosion_risk_management_research_report",
    "help_page",
    "international_development_fund",
    "maib_report",
    "manual",
    "manual_section",
    "medical_safety_alert",
    "ministerial_role",
    "person",
    "product_safety_alert_report_recall",
    "protected_food_drink_name",
    "raib_report",
    "research_for_development_output",
    "residential_property_tribunal_decision",
    "service_standard_report",
    "simple_smart_answer",
    "statutory_instrument",
    "tax_tribunal_decision",
    "uk_market_conformity_assessment_body",
    "utaac_decision"
  ] } } },
  { $project: { "url": true, "details.body": true } },
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
  { $project: { "url": true, "details.body.content": true } },
  { $unwind: "$details.body" },
  { $project: { url: true, html: "$details.body.content" } },
  { $out: "body_content"}
])
