#!/bin/bash

# Directories to sync from and to
SOURCE_DIR="terraform-staging"
TARGET_DIRS=("terraform-dev" "terraform")

# Exclude certain files
EXCLUDE_FILE="diff-exclude"

# Sync differences
for TARGET_DIR in "${TARGET_DIRS[@]}"; do
  rsync -av --exclude-from="$EXCLUDE_FILE" "$SOURCE_DIR/" "$TARGET_DIR/"
done
