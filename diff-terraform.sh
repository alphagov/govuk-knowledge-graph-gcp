#!/bin/bash

# Diff the terraform folder with any other folders named terraform-something.
# Exclude certain files that are expected to differ.
diffs=$(
  diff \
    --recursive \
    --exclude-from=diff-exclude \
    --from-file=terraform terraform-*
)

# Print any differences.
echo "$diffs"

# If there are any differences then exit with an error.
# https://stackoverflow.com/a/35165216/937932
if [[ $(echo $diffs | head -c1 | wc -c) -ne 0 ]]; then exit 1; fi
