// Bank holidays
CALL apoc.load.json("https://www.gov.uk/bank-holidays.json")
YIELD value
UNWIND apoc.map.sortedProperties(value) AS divisions
WITH divisions[1] AS division
WITH *, division.division AS id
CREATE (div:Division {
  url: "https://www.gov.uk/divisions/" + id,
  name: CASE id
    WHEN "england-and-wales" THEN "England and Wales"
    WHEN "northern-ireland" THEN "Northern Ireland"
    WHEN "scotland" THEN "Scotland"
    ELSE id
  END
})
WITH *
UNWIND division.events AS event
MERGE (holiday:BankHoliday {
  url: "https://www.gov.uk/bank-holidays/" + event.title,
  name: event.title
})
MERGE (date:Date {
  url: "https://www.gov.uk/dates/" + event.date,
  dateString: event.date
})
MERGE (holiday)-[:IS_OBSERVED_IN]->(div)
WITH *, CASE event.notes WHEN "" THEN NULL ELSE event.notes END AS note
MERGE (holiday)-[observance:IS_ON]->(date)
SET observance.notes = note
;
