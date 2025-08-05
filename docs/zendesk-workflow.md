# Zendesk workflow

This workflow queries the Zendesk API daily, to fetch any tickets that were updated the day before. These tickets are then loaded into a BigQuery table `tickets` in the `zendesk` dataset. If the ticket already exists in that table, then its record will be overwritten, so that only the latest record of each ticket is kept in the table.

## Example

1. January the 1st: a ticket with ID `10011` is created.
1. January the 2nd: This workflow is run. The table `zendesk.tickets` gets a new row for the new ticket with ID `10011`. Later on the same day, the ticket is "solved" in Zendesk.
1. January the 3th: This workflow is run again. The row for the ticket with ID `10011` in the table `zendesk.tickets` is overwritten with the latest data from the API, which marks it as "solved".

## Expiry

The table `zendesk.tickets` will automatically delete records of tickets that haven't been updated for a year.

## Backfilling

Execute the workflow manually, either in the web console, or at the command line with the `gcloud` CLI. Provide a value of `updated_at` for the date that you want to backfill. For example:

```sh
gcloud --project govuk-knowledge-graph-dev workflows run zendesk --location=europe-west2 --data='{"updated_at": "2025-01-01"}'
```
