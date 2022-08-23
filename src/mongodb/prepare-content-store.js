// This is a MongoDB script, not a normal javascript file.

// It creates datasets of nodes, edges and attributes, to be exported as CSV
// files.

// Switch databases
// https://stackoverflow.com/a/64681997
// Equivalent for "use <db>" command in mongo shell
db = db.getSiblingDB('content_store')

db.content_items.createIndex({ "document_type": 1 })

// Prepend https://gov.uk to every _id to create a complete URL.
// This doesn't affect any partial URLs elsewhere in the documents.
db.content_items.updateMany(
  {}, // everything
  [
    { $set: { "url": { "$concat": [ "https://www.gov.uk", "$_id" ] } } },
  ]
)

// Get the title from documents and strip leading and trailing whitespace
db.content_items.aggregate([
  { $match: { $and: [
    { "title": { $exists: true } },
    { "title": { $ne: null } },
    { "description.value": { $ne: "" } },
  ] } },
  { $project: { url: 1, title: { "$trim": { input: "$title" } } } },
  { $out: "title" }
])

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

// All step-by-step content as a string, following the schema:
// https://github.com/alphagov/govuk-content-schemas/blob/main/dist/formats/step_by_step_nav/frontend/schema.json
db.content_items.aggregate([
  { $match: { "document_type": "step_by_step_nav" } },
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
  { $out: "step_by_step_content" }
])

// All types of expanded links
db.content_items.aggregate([
  { $match: {
    "expanded_links": { $exists: true, $type: 'object', $ne: { } }
  } },
  { $project: { "url": true, "links": { $objectToArray: "$expanded_links" } } },
  { $project: {
    "url": true,
    "links": { $map: {
      input: "$links",
      as: "link",
      in: {
        link_type: "$$link.k",
        base_paths: { $reduce: {
          input: "$$link.v",
          initialValue: [ ],
          in: { $concatArrays : ["$$value", [ "$$this.base_path" ] ] }
        } }
      }
    } }
  } },
  { $unwind: "$links" },
  { $unwind: "$links.base_paths" },
  { $project: {
    "_id": false,
    "link_type": "$links.link_type",
    "from_url": "$url",
    "to_url": { "$concat": [ "https://www.gov.uk", "$links.base_paths" ] },
  } },
  { $out: "expanded_links" }
])

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
            case: { "$regexMatch": { input: "$link_url", regex: /^\\/ } },
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

// html content of parts of "guide" and "travel_advice"
db.content_items.aggregate([
  { $match: { "details.parts": { $exists: true } } },
  { $project: {
    "_id": false,
    "base_path": "$url",
    "details.parts": true,
  } },
  { $unwind: { path: "$details.parts", includeArrayIndex: "part_index" } },
  { $project: {
    base_path: true,
    part_index: true,
    slug: "$details.parts.slug",
    part_title: "$details.parts.title",
    body: { $filter: {
      input: "$details.parts.body",
      as: "item",
      cond: { $eq: [ "$$item.content_type", "text/html" ] }
    } },
  } },
  { $unwind: { path: "$body" } },
  { $project: {
    "url": { $concat: ["$base_path", "/", "$slug"] },
    "base_path": true,
    "slug": true,
    "part_index": true,
    "part_title": true,
    "html": "$body.content",
  } },
  {$out: "parts_content"}
])

// HTML content of "transaction", following the schema:
// https://github.com/alphagov/govuk-content-schemas/blob/main/dist/formats/transaction/frontend/schema.json
db.content_items.aggregate([
  { $match: { "document_type": "transaction" } },
  { $project: {
    "url": true,
    "details.introductory_paragraph": true,
    "details.start_button_text": true,
    "details.will_continue_on": true,
    "details.more_information": true,
    "details.what_you_need_to_know": true,
    "details.other_ways_to_apply": true,
  } },
  // Omit govspeak content
  { $redact: {
    $cond: {
      if: { $or: [
        { $eq: [ { $type : "$content_type"}, 'missing'] },
        { $eq: [ "$content_type", "text/html" ] },
      ] },
      then: "$$DESCEND",
      else: "$$PRUNE"
    },
  } },
  { $project: {
    url: true,
    content: { $concatArrays: [
      { $ifNull: [ "$details.introductory_paragraph.content", [] ] },
      [ { $ifNull: [ "$details.start_button_text", "" ] } ],
      { $ifNull: [ "$details.will_continue_on.content", [] ] },
      { $ifNull: [ "$details.more_information.content", [] ] },
      { $ifNull: [ "$details.what_you_need_to_know.content", [] ] },
      { $ifNull: [ "$details.other_ways_to_apply.content", [] ] },
    ] }
  } },
  // Concatenate all the strings, separated by newlines
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
  { $out: "transaction_content" }
])

// HTML content of "place", following the schema:
// https://github.com/alphagov/govuk-content-schemas/blob/main/dist/formats/place/frontend/schema.json
db.content_items.aggregate([
  { $match: { "document_type": "place" } },
  { $project: {
    "url": true,
    "details.introduction": true,
    "details.information": true,
    "details.need_to_know": true,
  } },
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
  { $project: {
    "url": true,
    introduction: { $map: {
      input: "$details.introduction",
      as: "item",
      in: "$$item.content"
    } },
    more_information: { $map: {
      input: "$details.more_information",
      as: "item",
      in: "$$item.content"
    } },
    need_to_know: { $map: {
      input: "$details.need_to_know",
      as: "item",
      in: "$$item.content"
    } },
  } },
  { $project: {
    "url": true,
    content: { $concatArrays: [
      { $ifNull: [ "$introduction", [] ] },
      { $ifNull: [ "$more_information", [] ] },
      { $ifNull: [ "$need_to_know", [] ] },
    ] }
  } },
  // Concatenate all the strings, separated by newlines
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
  { $out: "place_content" }
])

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
