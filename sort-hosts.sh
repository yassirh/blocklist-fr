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
        
        # Reconstruct the file: comments first, then sorted hosts
        cat "$file.comments" > "$file"
        if [ -s "$file.comments" ] && [ -s "$file.hosts" ]; then
            echo "" >> "$file"  # Add blank line between comments and hosts
        fi
        cat "$file.hosts" >> "$file"
        
        # Clean up temporary files
        rm -f "$file.comments" "$file.hosts"
        
        # Check if there are any changes
        if ! diff -q "$file" "$file.bak" > /dev/null; then
            echo -e "   ${GREEN}Sorted successfully (comments preserved)${NC}"
            changes_made=true
        else
            echo -e "   ${GREEN}Already sorted${NC}"
        fi
        
        # Clean up backup
        rm "$file.bak"
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
