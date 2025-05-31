#!/bin/bash

# Script to sort all host list files in the hosts/ directory
# Preserves comment lines (starting with #) at the top
# Usage: ./sort-hosts.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Sorting host list files...${NC}"

# Check if hosts directory exists
if [ ! -d "hosts" ]; then
    echo -e "${RED}Error: hosts/ directory not found${NC}"
    echo "Please run this script from the repository root directory."
    exit 1
fi

# Find all .txt files in the hosts directory
txt_files=(hosts/*.txt)

# Check if any .txt files exist
if [ ! -e "${txt_files[0]}" ]; then
    echo -e "${YELLOW}No .txt files found in hosts/ directory${NC}"
    exit 0
fi

changes_made=false

# Process each .txt file
for file in "${txt_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "Processing ${YELLOW}$file${NC}..."
        
        # Create a backup
        cp "$file" "$file.bak"
        
        # Create temporary files for comments and host entries
        grep '^#' "$file" > "$file.comments" 2>/dev/null || touch "$file.comments"
        grep -v '^#' "$file" | grep -v '^[[:space:]]*$' > "$file.hosts" 2>/dev/null || touch "$file.hosts"
        
        # Sort only the host entries (non-comment lines)
        if [ -s "$file.hosts" ]; then
            sort -k2 "$file.hosts" > "$file.hosts.sorted"
            mv "$file.hosts.sorted" "$file.hosts"
        fi
        
        # Count the number of domains
        domain_count=$(wc -l < "$file.hosts" | tr -d ' ')
        
        # Get the file basename for the header
        basename=$(basename "$file" .txt)
        # Capitalize first letter
        capitalized_basename="$(tr '[:lower:]' '[:upper:]' <<< ${basename:0:1})${basename:1}"
        
        # Generate header with current date and domain count
        current_date=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
        
        # Create header
        cat > "$file" << EOF
# French $capitalized_basename Domains Blocklist
# Description: Blocklist of $basename domains targeting French users
# Last updated: $current_date
# Total domains blocked: $domain_count
# Format: 0.0.0.0 domain.com
# 
# Source: https://github.com/yassirh/blocklist-fr
# License: MIT

EOF
        
        # Add the sorted hosts
        cat "$file.hosts" >> "$file"
        
        # Clean up temporary files
        rm -f "$file.comments" "$file.hosts"
        
        # Check if there are any meaningful changes (excluding timestamp)
        # Remove the "Last updated" line from both files for comparison
        grep -v "^# Last updated:" "$file" > "$file.compare" 2>/dev/null || touch "$file.compare"
        grep -v "^# Last updated:" "$file.bak" > "$file.bak.compare" 2>/dev/null || touch "$file.bak.compare"
        
        if ! diff -q "$file.compare" "$file.bak.compare" > /dev/null; then
            echo -e "   ${GREEN} Sorted successfully (meaningful changes detected)${NC}"
            changes_made=true
        else
            echo -e "   ${GREEN} No meaningful changes (only timestamp updated)${NC}"
            # Restore the original file since only timestamp changed
            cp "$file.bak" "$file"
        fi
        
        # Clean up comparison files and backup
        rm -f "$file.compare" "$file.bak.compare" "$file.bak"
    fi
done

if [ "$changes_made" = true ]; then
    echo -e "\n${GREEN}Sorting complete! Some files were modified.${NC}"
    echo -e "${YELLOW}Don't forget to commit your changes:${NC}"
    echo "   git add hosts/*.txt"
    echo "   git commit -m \"Sort host list files\""
else
    echo -e "\n${GREEN}All files were already sorted!${NC}"
fi
