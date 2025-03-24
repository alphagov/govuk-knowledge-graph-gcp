#!/bin/bash

# Run a script from a copy of the HEAD of the repository
# This sometimes fails with
#
# > ERROR: (gcloud.storage.cat) You do not currently have an active account selected.
#
# So retry for a few minutes.  Newly-built containers don't seem to work
# immediately.

MAX_RETRIES=10
RETRY_INTERVAL_SECONDS=60
COUNTER=0
CMD="gcloud storage cat gs://${PROJECT_ID}-repository/src/whitehall/run.sh"

while [ $COUNTER -lt $MAX_RETRIES ]; do
  $CMD
  if [ $? -eq 0 ]; then
    break
  else
    echo "Command failed, retrying in ${RETRY_INTERVAL_SECONDS} seconds..."
    sleep $RETRY_INTERVAL_SECONDS
    let COUNTER=COUNTER+1
  fi
done

if [ $COUNTER -eq $MAX_RETRIES ]; then
  echo "Command failed after $MAX_RETRIES attempts, exiting..."
  exit 1
fi

$CMD | bash
