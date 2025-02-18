#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting execute permissions for all .sh files in: $SCRIPT_DIR and subdirectories..."

# Find and set execute permissions on all .sh files
find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "All .sh files are now executable."
